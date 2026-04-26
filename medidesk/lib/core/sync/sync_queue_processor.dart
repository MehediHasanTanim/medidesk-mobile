import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../database/app_database.dart';
import '../database/daos/sync_queue_dao.dart';
import '../database/daos/patient_dao.dart';
import '../database/daos/appointment_dao.dart';
import '../database/daos/consultation_dao.dart';
import '../database/daos/test_order_dao.dart';
import '../database/daos/invoice_dao.dart';
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
    final backoffMs =
        (1 << retryCount) * 1000; // 2s, 4s, 8s
    final nextRetryAt =
        DateTime.now().millisecondsSinceEpoch + backoffMs;

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
      'patient' => ApiEndpoints.patients,
      'patient_note' => ApiEndpoints.patientNotes,
      'appointment' => ApiEndpoints.appointments,
      'consultation' => ApiEndpoints.consultations,
      'prescription' => ApiEndpoints.prescriptions,
      'prescription_items' => ApiEndpoints.prescriptionItems,
      'test_order' => ApiEndpoints.testOrders,
      'invoice' => ApiEndpoints.invoices,
      'invoice_items' => ApiEndpoints.invoiceItems,
      'payment' => ApiEndpoints.payments,
      _ => throw SyncException(
          'Unknown entity type: $entityType',
          entityType: entityType,
          localId: '',
        ),
    };
  }

  Future<String?> _getServerId(String entityType, String localId) async {
    return switch (entityType) {
      'patient' => (await _db.patientDao.getById(localId))?.serverId,
      'appointment' =>
        (await _db.appointmentDao.getById(localId))?.serverId,
      'consultation' =>
        (await _db.consultationDao.getById(localId))?.serverId,
      'invoice' => (await _db.invoiceDao.getById(localId))?.serverId,
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
        await _db.patientDao.updateSyncStatus(
          localId,
          'synced',
          serverId: serverId,
        );
      case 'appointment':
        await _db.appointmentDao.updateSyncStatus(
          localId,
          'synced',
          serverId: serverId,
        );
      case 'consultation':
        await _db.consultationDao.updateSyncStatus(
          localId,
          'synced',
          serverId: serverId,
        );
      case 'test_order':
        await _db.testOrderDao.updateSyncStatus(
          localId,
          'synced',
          serverId: serverId,
        );
      case 'invoice':
        await _db.invoiceDao.updateSyncStatus(
          localId,
          'synced',
          serverId: serverId,
        );
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
        await _db.appointmentDao.updateSyncStatus(localId, status);
      case 'consultation':
        await _db.consultationDao.updateSyncStatus(localId, status);
      case 'test_order':
        await _db.testOrderDao.updateSyncStatus(localId, status);
      case 'invoice':
        await _db.invoiceDao.updateSyncStatus(localId, status);
    }
  }
}
