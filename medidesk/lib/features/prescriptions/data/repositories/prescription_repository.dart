import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/sync/sync_service.dart';
import '../mappers/prescription_mapper.dart';
import '../models/prescription_models.dart';

// ── Interface ─────────────────────────────────────────────────────────────

abstract class IPrescriptionRepository {
  Stream<Prescription?> watchByConsultation(String consultationLocalId);
  Stream<List<Prescription>> watchByPatient(String patientLocalId);
  Stream<List<PrescriptionItem>> watchItems(String prescriptionLocalId);
  Future<Prescription?> getById(String localId);
  Future<void> createPrescription(CreatePrescriptionRequest req);
  Future<void> updateItems(UpdatePrescriptionRequest req);

  /// §7.5 — Download PDF. Requires the backend [serverId]; caller must ensure
  /// the prescription is synced before calling this (online-only).
  Future<File> downloadPdf(String serverId);

  /// §2.5 — Approve is online-only (authorization action).
  Future<void> approvePrescription(String localId);

  /// §2.5 — Send is online-only (external delivery).
  Future<void> sendPrescription(String localId);
}

// ── Implementation ────────────────────────────────────────────────────────

class PrescriptionRepository implements IPrescriptionRepository {
  PrescriptionRepository({
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
  Stream<Prescription?> watchByConsultation(String consultationLocalId) =>
      _db.prescriptionDao
          .watchByConsultation(consultationLocalId)
          .map((row) => row == null ? null : PrescriptionMapper.fromRow(row));

  @override
  Stream<List<Prescription>> watchByPatient(String patientLocalId) =>
      _db.prescriptionDao
          .watchByPatient(patientLocalId)
          .map((rows) => rows.map(PrescriptionMapper.fromRow).toList());

  @override
  Stream<List<PrescriptionItem>> watchItems(String prescriptionLocalId) =>
      _db.prescriptionDao
          .watchByPrescription(prescriptionLocalId)
          .map((rows) => rows.map(PrescriptionMapper.itemFromRow).toList());

  @override
  Future<Prescription?> getById(String localId) async {
    final row = await _db.prescriptionDao.getById(localId);
    return row == null ? null : PrescriptionMapper.fromRow(row);
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  @override
  Future<void> createPrescription(CreatePrescriptionRequest req) async {
    // §7.3 — Create prescription with items in one Drift transaction.
    final prescLocalId = _uuid.v4();
    final prescCompanion = PrescriptionMapper.toCreateCompanion(
      prescLocalId,
      req,
    );

    final itemCompanions = req.items.map((item) {
      final itemLocalId = PrescriptionMapper.generateItemId();
      return PrescriptionMapper.toItemCompanion(itemLocalId, prescLocalId, item);
    }).toList();

    await _db.transaction(() async {
      await _db.prescriptionDao.upsertPrescription(prescCompanion);
      if (itemCompanions.isNotEmpty) {
        await _db.prescriptionDao.replaceItems(prescLocalId, itemCompanions);
      }
    });

    // Items are bundled in the CREATE payload — no separate sync ops per item.
    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'prescription',
      operation: 'CREATE',
      localId: prescLocalId,
      payloadJson: jsonEncode({
        'local_id': prescLocalId,
        'consultation_id': req.consultationId,
        'patient_id': req.patientId,
        if (req.followUpDate != null) 'follow_up_date': req.followUpDate,
        'items': req.items
            .map((item) => {
                  'medicine_id': item.medicineId,
                  'medicine_name': item.medicineName,
                  'morning': item.morning,
                  'afternoon': item.afternoon,
                  'evening': item.evening,
                  'duration_days': item.durationDays,
                  'route': item.route,
                  if (item.instructions.isNotEmpty)
                    'instructions': item.instructions,
                })
            .toList(),
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> updateItems(UpdatePrescriptionRequest req) async {
    // §7.3 — Edit uses replace-wholesale strategy.
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final itemCompanions = req.items.map((item) {
      final itemLocalId = PrescriptionMapper.generateItemId();
      return PrescriptionMapper.toItemCompanion(itemLocalId, req.localId, item);
    }).toList();

    await _db.transaction(() async {
      // Mark prescription as pending on update
      await _db.prescriptionDao.updateSyncStatus(req.localId, 'pending');
      if (req.followUpDate != null) {
        await _db.prescriptionDao.upsertPrescription(PrescriptionsCompanion(
          id: Value(req.localId),
          followUpDate: Value(req.followUpDate),
          lastModified: Value(nowMs),
          syncStatus: const Value('pending'),
        ));
      }
      await _db.prescriptionDao.replaceItems(req.localId, itemCompanions);
    });

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'prescription',
      operation: 'UPDATE',
      localId: req.localId,
      payloadJson: jsonEncode({
        if (req.followUpDate != null) 'follow_up_date': req.followUpDate,
        'items': req.items
            .map((item) => {
                  'medicine_id': item.medicineId,
                  'medicine_name': item.medicineName,
                  'morning': item.morning,
                  'afternoon': item.afternoon,
                  'evening': item.evening,
                  'duration_days': item.durationDays,
                  'route': item.route,
                  if (item.instructions.isNotEmpty)
                    'instructions': item.instructions,
                })
            .toList(),
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  // ── §7.5 Online-only actions ──────────────────────────────────────────

  @override
  Future<File> downloadPdf(String serverId) async {
    final resp = await _dio.get<List<int>>(
      ApiEndpoints.prescriptionPdf(serverId),
      queryParameters: {'download': 'true'},
      options: Options(responseType: ResponseType.bytes),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/prescription_$serverId.pdf');
    await file.writeAsBytes(resp.data!);
    return file;
  }

  @override
  Future<void> approvePrescription(String localId) async {
    final prescription = await getById(localId);
    if (prescription == null) {
      throw const NetworkException('Prescription not found');
    }
    if (prescription.serverId == null) {
      throw const NetworkException('Prescription not yet synced to server');
    }
    await _dio.post<void>(
      ApiEndpoints.prescriptionApprove(prescription.serverId!),
    );
    await _db.prescriptionDao.updateSyncStatus(localId, 'synced');
  }

  @override
  Future<void> sendPrescription(String localId) async {
    final prescription = await getById(localId);
    if (prescription == null) {
      throw const NetworkException('Prescription not found');
    }
    if (prescription.serverId == null) {
      throw const NetworkException('Prescription not yet synced to server');
    }
    await _dio.post<void>(
      ApiEndpoints.prescriptionSend(prescription.serverId!),
    );
  }
}
