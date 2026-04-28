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
import '../mappers/billing_mapper.dart';
import '../models/billing_models.dart';

// ── Interface ─────────────────────────────────────────────────────────────

abstract class IBillingRepository {
  // Read — reactive Drift streams
  Stream<List<Invoice>> watchAll();
  Stream<List<Invoice>> watchByPatient(String patientLocalId);
  Stream<List<InvoiceItem>> watchItems(String invoiceLocalId);
  Stream<List<Payment>> watchPayments(String invoiceLocalId);
  Future<Invoice?> getById(String localId);

  // Mutations (offline-safe)
  Future<void> createInvoice(CreateInvoiceRequest req);
  Future<void> updateStatus(String localId, String status);
  Future<void> deleteInvoice(String localId);
  Future<void> recordPayment(RecordPaymentRequest req);

  // Online-only
  Future<File> downloadPdf(String serverId);
  Future<IncomeReport> getIncomeReport({
    required String fromDate,
    required String toDate,
  });
}

// ── Implementation ────────────────────────────────────────────────────────

class BillingRepository implements IBillingRepository {
  BillingRepository({
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
  Stream<List<Invoice>> watchAll() =>
      _db.invoiceDao.watchAll().map(
            (rows) => rows.map(BillingMapper.fromRow).toList(),
          );

  @override
  Stream<List<Invoice>> watchByPatient(String patientLocalId) =>
      _db.invoiceDao
          .watchByPatient(patientLocalId)
          .map((rows) => rows.map(BillingMapper.fromRow).toList());

  @override
  Stream<List<InvoiceItem>> watchItems(String invoiceLocalId) =>
      _db.invoiceDao
          .watchItems(invoiceLocalId)
          .map((rows) => rows.map(BillingMapper.itemFromRow).toList());

  @override
  Stream<List<Payment>> watchPayments(String invoiceLocalId) =>
      _db.invoiceDao
          .watchPayments(invoiceLocalId)
          .map((rows) => rows.map(BillingMapper.paymentFromRow).toList());

  @override
  Future<Invoice?> getById(String localId) async {
    final row = await _db.invoiceDao.getById(localId);
    return row == null ? null : BillingMapper.fromRow(row);
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  @override
  Future<void> createInvoice(CreateInvoiceRequest req) async {
    // §9.3 — Create invoice + items in one Drift transaction.
    final invoiceLocalId = _uuid.v4();
    final invoiceCompanion = BillingMapper.toCreateCompanion(invoiceLocalId, req);

    final itemCompanions = req.items.map((item) {
      final itemLocalId = _uuid.v4();
      return BillingMapper.itemToCompanion(itemLocalId, invoiceLocalId, item);
    }).toList();

    await _db.transaction(() async {
      await _db.invoiceDao.upsertInvoice(invoiceCompanion);
      if (itemCompanions.isNotEmpty) {
        await _db.invoiceDao.replaceItems(invoiceLocalId, itemCompanions);
      }
    });

    // Items are bundled in the CREATE payload — same pattern as prescriptions.
    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'invoice',
      operation: 'CREATE',
      localId: invoiceLocalId,
      payloadJson: jsonEncode({
        'local_id': invoiceLocalId,
        'patient_id': req.patientId,
        if (req.consultationId != null) 'consultation_id': req.consultationId,
        'discount_percent': req.discountPercent,
        'items': req.items
            .map((item) => {
                  'description': item.description,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice,
                })
            .toList(),
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> updateStatus(String localId, String status) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _db.invoiceDao.upsertInvoice(InvoicesCompanion(
      id: Value(localId),
      status: Value(status),
      lastModified: Value(nowMs),
      syncStatus: const Value('pending'),
    ));

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'invoice',
      operation: 'UPDATE',
      localId: localId,
      payloadJson: jsonEncode({'status': status}),
      createdAt: nowMs,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> deleteInvoice(String localId) async {
    await _db.invoiceDao.softDelete(localId);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'invoice',
      operation: 'DELETE',
      localId: localId,
      payloadJson: jsonEncode({'local_id': localId}),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> recordPayment(RecordPaymentRequest req) async {
    // §9.3 — Payment dependency: SyncQueueProcessor resolves invoice server ID
    // via invoice_local_id in the payload before POSTing to /payments/.
    final paymentLocalId = _uuid.v4();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final companion = BillingMapper.paymentToCompanion(paymentLocalId, req);

    await _db.invoiceDao.insertPayment(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'payment',
      operation: 'CREATE',
      localId: paymentLocalId,
      payloadJson: jsonEncode({
        'local_id': paymentLocalId,
        'invoice_local_id': req.invoiceLocalId,
        'amount': req.amount,
        'method': req.method,
        if (req.transactionRef.isNotEmpty) 'transaction_ref': req.transactionRef,
      }),
      createdAt: nowMs,
    ));

    unawaited(_syncService.pushSync());
  }

  // ── §9.2 Online-only ──────────────────────────────────────────────────

  @override
  Future<File> downloadPdf(String serverId) async {
    final resp = await _dio.get<List<int>>(
      ApiEndpoints.invoicePdf(serverId),
      queryParameters: {'download': 'true'},
      options: Options(responseType: ResponseType.bytes),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_$serverId.pdf');
    await file.writeAsBytes(resp.data!);
    return file;
  }

  @override
  Future<IncomeReport> getIncomeReport({
    required String fromDate,
    required String toDate,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.incomeReport,
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    if (resp.data == null) throw const NetworkException('Empty income report response');
    return IncomeReport.fromJson(resp.data!);
  }
}
