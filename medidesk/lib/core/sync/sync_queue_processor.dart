import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../database/app_database.dart';
import '../error/app_exception.dart';
import '../error/error_handler.dart';
import '../network/api_endpoints.dart';

class SyncQueueProcessor {
  const SyncQueueProcessor({
    required Dio dio,
    required AppDatabase db,
  })  : _dio = dio,
        _db = db;

  final Dio _dio;
  final AppDatabase _db;

  static const int _maxRetries = 3;

  Future<void> pushSync() async {
    final pending = await _db.syncQueueDao.getPending(limit: 20);

    for (final entry in pending) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (entry.nextRetryAt > nowMs) continue;

      try {
        await _db.syncQueueDao.markProcessing(entry.id);
        final serverId = await _dispatchApiCall(entry);

        if (entry.operation == 'CREATE' && serverId != null) {
          await _updateServerId(entry.entityType, entry.localId, serverId);
        }

        await _db.syncQueueDao.markSynced(entry.id);
        await _updateSyncStatus(entry.entityType, entry.localId, 'synced');
      } on DioException catch (e) {
        final appEx = mapDioException(e);
        await _handleFailure(entry, appEx.message);
      } on AppException catch (e) {
        await _handleFailure(entry, e.message);
      } catch (e) {
        await _handleFailure(entry, e.toString());
      }
    }
  }

  Future<void> _handleFailure(SyncQueueEntry entry, String errorMessage) async {
    final retryCount = entry.retryCount + 1;
    final backoffMs = (1 << retryCount) * 1000; // 2s, 4s, 8s
    final nextRetryAt = DateTime.now().millisecondsSinceEpoch + backoffMs;

    await _db.syncQueueDao.markFailed(
      entry.id,
      errorMessage,
      nextRetryAt,
      retryCount: retryCount,
    );

    if (retryCount >= _maxRetries) {
      await _updateSyncStatus(entry.entityType, entry.localId, 'failed');
    }
  }

  Future<String?> _dispatchApiCall(SyncQueueEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;

    // ── Inline: patient_note — nested path requires parent server ID ──────
    if (entry.entityType == 'patient_note') {
      final patientLocalId = payload['patient_id'] as String;
      final patientServerId = await _getServerId('patient', patientLocalId);
      if (patientServerId == null) return null; // wait for patient CREATE to sync
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientNotes(patientServerId),
        data: {'content': payload['content'], 'local_id': entry.localId},
      );
      return resp.data?['id'] as String?;
    }

    // ── Inline: consultation_vitals — PATCH to nested vitals path ─────────
    if (entry.entityType == 'consultation_vitals') {
      final consultationServerId =
          await _getServerId('consultation', entry.localId);
      if (consultationServerId == null) return null;
      await _dio.patch<void>(
        ApiEndpoints.consultationVitals(consultationServerId),
        data: payload,
      );
      return null;
    }

    // ── Inline: test_order_bulk — POST to consultation test-orders path ───
    if (entry.entityType == 'test_order_bulk') {
      final consultationLocalId = payload['consultation_id'] as String;
      final consultationServerId =
          await _getServerId('consultation', consultationLocalId);
      if (consultationServerId == null) return null; // wait for consultation sync
      await _dio.post<void>(
        ApiEndpoints.consultationTestOrders(consultationServerId),
        data: payload,
      );
      return null;
    }

    final entityPath = _entityPath(entry.entityType);

    switch (entry.operation) {
      case 'CREATE':
        payload['local_id'] = entry.localId;
        final resp = await _dio.post<Map<String, dynamic>>(
          entityPath,
          data: payload,
        );
        return resp.data?['id'] as String?;

      case 'UPDATE':
        final existingServerId = await _getServerId(
          entry.entityType,
          entry.localId,
        );
        if (existingServerId == null) {
          // Not yet synced; skip UPDATE — CREATE will handle it
          return null;
        }
        await _dio.patch<void>(
          '$entityPath$existingServerId/',
          data: payload,
        );
        return null;

      case 'DELETE':
        final existingServerId = await _getServerId(
          entry.entityType,
          entry.localId,
        );
        if (existingServerId == null) return null;
        await _dio.delete<void>('$entityPath$existingServerId/');
        return null;

      default:
        throw SyncException(
          'Unknown operation: ${entry.operation}',
          entityType: entry.entityType,
          localId: entry.localId,
        );
    }
  }

  String _entityPath(String entityType) {
    return switch (entityType) {
      'patient'      => ApiEndpoints.patients,
      'appointment'  => ApiEndpoints.appointments,
      'walk_in'      => ApiEndpoints.walkIn,
      'consultation' => ApiEndpoints.consultations,
      'prescription' => ApiEndpoints.prescriptions,
      'test_order'   => ApiEndpoints.testOrders,
      'invoice'      => ApiEndpoints.invoices,
      'payment'      => ApiEndpoints.payments,
      _ => throw SyncException(
          'Unknown entity type: $entityType',
          entityType: entityType,
          localId: '',
        ),
    };
  }

  Future<String?> _getServerId(String entityType, String localId) async {
    return switch (entityType) {
      'patient'      => (await _db.patientDao.getById(localId))?.serverId,
      'appointment'  => (await _db.appointmentDao.getById(localId))?.serverId,
      'walk_in'      => (await _db.appointmentDao.getById(localId))?.serverId,
      'consultation' => (await _db.consultationDao.getById(localId))?.serverId,
      'prescription' => (await _db.prescriptionDao.getById(localId))?.serverId,
      'test_order'   => (await _db.testOrderDao.getById(localId))?.serverId,
      'invoice'      => (await _db.invoiceDao.getById(localId))?.serverId,
      _ => null,
    };
  }

  Future<void> _updateServerId(
    String entityType,
    String localId,
    String serverId,
  ) async {
    switch (entityType) {
      case 'patient':
        await _db.patientDao.updateSyncStatus(localId, 'synced',
            serverId: serverId);
      case 'appointment':
      case 'walk_in':
        await _db.appointmentDao.updateSyncStatus(localId, 'synced',
            serverId: serverId);
      case 'consultation':
        await _db.consultationDao.updateSyncStatus(localId, 'synced',
            serverId: serverId);
      case 'prescription':
        await _db.prescriptionDao.updateSyncStatus(localId, 'synced',
            serverId: serverId);
      case 'test_order':
        await _db.testOrderDao.updateSyncStatus(localId, 'synced',
            serverId: serverId);
      case 'invoice':
        await _db.invoiceDao.updateSyncStatus(localId, 'synced',
            serverId: serverId);
      case 'payment':
        await _db.invoiceDao.updatePaymentSyncStatus(localId, 'synced',
            serverId: serverId);
      case 'patient_note':
        await _db.patientDao.updateNoteSyncStatus(localId, 'synced',
            serverId: serverId);
    }
  }

  Future<void> _updateSyncStatus(
    String entityType,
    String localId,
    String status,
  ) async {
    switch (entityType) {
      case 'patient':
        await _db.patientDao.updateSyncStatus(localId, status);
      case 'appointment':
      case 'walk_in':
        await _db.appointmentDao.updateSyncStatus(localId, status);
      case 'consultation':
      case 'consultation_vitals':
        await _db.consultationDao.updateSyncStatus(localId, status);
      case 'prescription':
        await _db.prescriptionDao.updateSyncStatus(localId, status);
      case 'test_order':
      case 'test_order_bulk':
        await _db.testOrderDao.updateSyncStatus(localId, status);
      case 'invoice':
        await _db.invoiceDao.updateSyncStatus(localId, status);
      case 'payment':
        await _db.invoiceDao.updatePaymentSyncStatus(localId, status);
      case 'patient_note':
        await _db.patientDao.updateNoteSyncStatus(localId, status);
    }
  }
}
