import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/sync/sync_service.dart';
import '../mappers/consultation_mapper.dart';
import '../models/consultation_models.dart';

abstract class IConsultationRepository {
  Stream<ConsultationRow?> watchByAppointment(String appointmentLocalId);
  Stream<List<Consultation>> watchByPatient(String patientLocalId);
  Stream<Consultation?> watchById(String localId);
  Future<Consultation?> getById(String localId);
  Future<void> startConsultation(StartConsultationRequest req);
  Future<void> updateDraft(UpdateConsultationRequest req);
  Future<void> recordVitals(UpdateVitalsRequest req);
  Future<void> completeConsultation(
      CompleteConsultationRequest req, Dio dio);
  Future<void> deleteConsultation(String localId);
}

class ConsultationRepository implements IConsultationRepository {
  ConsultationRepository({
    required AppDatabase db,
    required SyncService syncService,
  })  : _db = db,
        _syncService = syncService;

  final AppDatabase _db;
  final SyncService _syncService;
  final _uuid = const Uuid();

  @override
  Stream<ConsultationRow?> watchByAppointment(String appointmentLocalId) =>
      _db.consultationDao.watchByAppointment(appointmentLocalId);

  @override
  Stream<List<Consultation>> watchByPatient(String patientLocalId) =>
      _db.consultationDao
          .watchByPatient(patientLocalId)
          .map((rows) => rows.map(ConsultationMapper.fromRow).toList());

  @override
  Stream<Consultation?> watchById(String localId) =>
      _db.consultationDao
          .watchById(localId)
          .map((row) => row == null ? null : ConsultationMapper.fromRow(row));

  @override
  Future<Consultation?> getById(String localId) async {
    final row = await _db.consultationDao.getById(localId);
    return row == null ? null : ConsultationMapper.fromRow(row);
  }

  @override
  Future<void> startConsultation(StartConsultationRequest req) async {
    final localId = _uuid.v4();
    final companion = ConsultationMapper.toCreateCompanion(localId, req);

    await _db.consultationDao.upsertConsultation(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'consultation',
      operation: 'CREATE',
      localId: localId,
      payloadJson: jsonEncode({
        'appointment_id': req.appointmentId,
        'patient_id': req.patientId,
        'chief_complaints': req.chiefComplaints,
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> updateDraft(UpdateConsultationRequest req) async {
    final companion = ConsultationMapper.toUpdateCompanion(req);
    await _db.consultationDao.updateConsultation(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'consultation',
      operation: 'UPDATE',
      localId: req.localId,
      payloadJson: jsonEncode({
        if (req.chiefComplaints != null)
          'chief_complaints': req.chiefComplaints,
        if (req.clinicalFindings != null)
          'clinical_findings': req.clinicalFindings,
        if (req.diagnosis != null) 'diagnosis': req.diagnosis,
        if (req.notes != null) 'notes': req.notes,
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> recordVitals(UpdateVitalsRequest req) async {
    final companion = ConsultationMapper.toVitalsCompanion(req);
    await _db.consultationDao.updateConsultation(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'consultation_vitals',
      operation: 'UPDATE',
      localId: req.localId,
      payloadJson: jsonEncode({
        if (req.bpSystolic != null) 'bp_systolic': req.bpSystolic,
        if (req.bpDiastolic != null) 'bp_diastolic': req.bpDiastolic,
        if (req.pulse != null) 'pulse': req.pulse,
        if (req.temperature != null) 'temperature': req.temperature,
        if (req.weight != null) 'weight': req.weight,
        if (req.height != null) 'height': req.height,
        if (req.spo2 != null) 'spo2': req.spo2,
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> completeConsultation(
    CompleteConsultationRequest req,
    Dio dio,
  ) async {
    final consultation = await getById(req.localId);
    if (consultation == null) {
      throw const NetworkException('Consultation not found');
    }
    if (consultation.serverId == null) {
      throw const NetworkException(
          'Consultation not yet synced to server');
    }

    final now = DateTime.now();
    await dio.post<void>(
      ApiEndpoints.consultationComplete(consultation.serverId!),
      data: {
        'diagnosis': req.diagnosis,
        if (req.clinicalFindings.isNotEmpty)
          'clinical_findings': req.clinicalFindings,
        if (req.notes.isNotEmpty) 'notes': req.notes,
        if (req.bpSystolic != null) 'bp_systolic': req.bpSystolic,
        if (req.bpDiastolic != null) 'bp_diastolic': req.bpDiastolic,
        if (req.pulse != null) 'pulse': req.pulse,
        if (req.temperature != null) 'temperature': req.temperature,
        if (req.weight != null) 'weight': req.weight,
        if (req.height != null) 'height': req.height,
        if (req.spo2 != null) 'spo2': req.spo2,
      },
    );

    await _db.consultationDao.markCompleted(
      req.localId,
      now.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> deleteConsultation(String localId) async {
    await _db.consultationDao.softDelete(localId);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'consultation',
      operation: 'DELETE',
      localId: localId,
      payloadJson: jsonEncode({'local_id': localId}),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }
}
