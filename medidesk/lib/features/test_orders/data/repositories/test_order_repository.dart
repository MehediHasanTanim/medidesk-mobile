import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/sync/sync_service.dart';
import '../mappers/test_order_mapper.dart';
import '../models/test_order_models.dart';

// ── Interface ─────────────────────────────────────────────────────────────

abstract class ITestOrderRepository {
  /// Reactive stream of all test orders for a consultation (offline-first).
  Stream<List<TestOrder>> watchByConsultation(String consultationLocalId);

  /// Reactive stream of all test orders for a patient (offline-first).
  Stream<List<TestOrder>> watchByPatient(String patientLocalId);

  /// Single test order by local ID.
  Future<TestOrder?> getById(String localId);

  /// §10.3 — Bulk create: inserts all orders locally then enqueues one
  /// 'test_order_bulk' sync op that POSTs to /consultations/{cId}/test-orders/.
  Future<void> createBulkTestOrders(BulkCreateTestOrderRequest req);

  /// Update a single test order locally and enqueue a PATCH op.
  Future<void> updateTestOrder(UpdateTestOrderRequest req);

  /// Soft-delete a test order locally and enqueue a DELETE op.
  Future<void> deleteTestOrder(String localId);

  /// §10.2 — Online-only: GET /test-orders/mine/.
  Future<List<TestOrderSummary>> fetchMyTestOrders();

  /// §10.2 — Online-only: GET /test-orders/pending/?patient_id=.
  Future<List<TestOrderSummary>> fetchPendingTestOrders({String? patientId});
}

// ── Implementation ────────────────────────────────────────────────────────

class TestOrderRepository implements ITestOrderRepository {
  TestOrderRepository({
    required AppDatabase db,
    required SyncService syncService,
    required Dio dio,
  })  : _db = db,
        _syncService = syncService,
        _dio = dio;

  final AppDatabase _db;
  final SyncService _syncService;
  final Dio _dio;
  final _uuid = const Uuid();

  // ── Read ──────────────────────────────────────────────────────────────

  @override
  Stream<List<TestOrder>> watchByConsultation(String consultationLocalId) =>
      _db.testOrderDao
          .watchByConsultation(consultationLocalId)
          .map((rows) => rows.map(TestOrderMapper.fromRow).toList());

  @override
  Stream<List<TestOrder>> watchByPatient(String patientLocalId) =>
      _db.testOrderDao
          .watchByPatient(patientLocalId)
          .map((rows) => rows.map(TestOrderMapper.fromRow).toList());

  @override
  Future<TestOrder?> getById(String localId) async {
    final row = await _db.testOrderDao.getById(localId);
    return row == null ? null : TestOrderMapper.fromRow(row);
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  @override
  Future<void> createBulkTestOrders(BulkCreateTestOrderRequest req) async {
    // 1. Assign a local UUID to each order and insert individually into Drift.
    final orderInputs = <({String localId, TestOrderInput input})>[];
    for (final input in req.orders) {
      final localId = _uuid.v4();
      orderInputs.add((localId: localId, input: input));

      final companion = TestOrderMapper.toCreateCompanion(
        localId: localId,
        consultationLocalId: req.consultationLocalId,
        patientId: req.patientId,
        input: input,
      );
      await _db.testOrderDao.insertTestOrder(companion);
    }

    // 2. Enqueue one 'test_order_bulk' op for the entire batch.
    //    SyncQueueProcessor resolves consultation serverId before pushing.
    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'test_order_bulk',
      operation: 'CREATE',
      // Use consultationLocalId as the group key so the processor can resolve it.
      localId: req.consultationLocalId,
      payloadJson: jsonEncode({
        'consultation_id': req.consultationLocalId,
        'orders': orderInputs
            .map((e) => {
                  'local_id': e.localId,
                  'test_name': e.input.testName,
                  if (e.input.labName.isNotEmpty) 'lab_name': e.input.labName,
                  if (e.input.notes.isNotEmpty) 'notes': e.input.notes,
                })
            .toList(),
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    // 3. Trigger push if online (non-blocking).
    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> updateTestOrder(UpdateTestOrderRequest req) async {
    final companion = TestOrderMapper.toUpdateCompanion(req);
    await _db.testOrderDao.updateTestOrder(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'test_order',
      operation: 'UPDATE',
      localId: req.localId,
      payloadJson: jsonEncode(_updateRequestToJson(req)),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> deleteTestOrder(String localId) async {
    await _db.testOrderDao.softDelete(localId);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'test_order',
      operation: 'DELETE',
      localId: localId,
      payloadJson: jsonEncode({'local_id': localId}),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  // ── §10.2 Online-only ─────────────────────────────────────────────────

  @override
  Future<List<TestOrderSummary>> fetchMyTestOrders() async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.myTestOrders,
    );
    final results =
        (resp.data!['results'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
    return results.map(TestOrderSummary.fromJson).toList();
  }

  @override
  Future<List<TestOrderSummary>> fetchPendingTestOrders({
    String? patientId,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.pendingTestOrders,
      queryParameters: {
        if (patientId != null) 'patient_id': patientId,
      },
    );
    final results =
        (resp.data!['results'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
    return results.map(TestOrderSummary.fromJson).toList();
  }

  // ── JSON serialisation helpers ────────────────────────────────────────

  Map<String, dynamic> _updateRequestToJson(UpdateTestOrderRequest req) => {
        if (req.testName != null) 'test_name': req.testName,
        if (req.labName != null) 'lab_name': req.labName,
        if (req.notes != null) 'notes': req.notes,
        if (req.isCompleted != null) 'is_completed': req.isCompleted,
        if (req.completedAt != null) 'completed_at': req.completedAt,
      };
}
