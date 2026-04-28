import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../mappers/appointment_mapper.dart';
import '../models/appointment_model.dart';

abstract class IAppointmentRepository {
  Stream<List<Appointment>> watchByDate(DateTime date);
  Stream<List<Appointment>> watchByPatient(String patientLocalId);
  Stream<List<Appointment>> watchTodayQueue(DateTime date);
  Future<Appointment?> getById(String localId);
  Future<Appointment?> getByServerId(String serverId);
  Future<void> createAppointment(CreateAppointmentRequest req);
  Future<void> createWalkIn(WalkInRequest req);
  Future<void> updateAppointment(UpdateAppointmentRequest req);
  Future<void> deleteAppointment(String localId);
  Future<void> updateStatus(String localId, String status);
  Future<void> assignToken(String localId, int tokenNumber);
}

class AppointmentRepository implements IAppointmentRepository {
  AppointmentRepository({
    required AppDatabase db,
    required SyncService syncService,
  })  : _db = db,
        _syncService = syncService;

  final AppDatabase _db;
  final SyncService _syncService;
  final _uuid = const Uuid();

  @override
  Stream<List<Appointment>> watchByDate(DateTime date) =>
      _db.appointmentDao
          .watchByDate(date)
          .map((rows) => rows.map(AppointmentMapper.fromRow).toList());

  @override
  Stream<List<Appointment>> watchByPatient(String patientLocalId) =>
      _db.appointmentDao
          .watchByPatient(patientLocalId)
          .map((rows) => rows.map(AppointmentMapper.fromRow).toList());

  @override
  Stream<List<Appointment>> watchTodayQueue(DateTime date) =>
      _db.appointmentDao
          .watchTodayQueue(date)
          .map((rows) => rows.map(AppointmentMapper.fromRow).toList());

  @override
  Future<Appointment?> getById(String localId) async {
    final row = await _db.appointmentDao.getById(localId);
    return row == null ? null : AppointmentMapper.fromRow(row);
  }

  @override
  Future<Appointment?> getByServerId(String serverId) async {
    final row = await _db.appointmentDao.getByServerId(serverId);
    return row == null ? null : AppointmentMapper.fromRow(row);
  }

  @override
  Future<void> createAppointment(CreateAppointmentRequest req) async {
    final localId = _uuid.v4();
    final companion = AppointmentMapper.toCreateCompanion(localId, req);

    await _db.appointmentDao.insertAppointment(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'appointment',
      operation: 'CREATE',
      localId: localId,
      payloadJson: jsonEncode(_createToJson(req)),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> createWalkIn(WalkInRequest req) async {
    final localId = _uuid.v4();
    final companion = AppointmentMapper.toWalkInCompanion(localId, req);

    await _db.appointmentDao.insertAppointment(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'walk_in',
      operation: 'CREATE',
      localId: localId,
      payloadJson: jsonEncode(_walkInToJson(req)),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> updateAppointment(UpdateAppointmentRequest req) async {
    final companion = AppointmentMapper.toUpdateCompanion(req);
    await _db.appointmentDao.updateAppointment(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'appointment',
      operation: 'UPDATE',
      localId: req.localId,
      payloadJson: jsonEncode(_updateToJson(req)),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> deleteAppointment(String localId) async {
    await _db.appointmentDao.softDelete(localId);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'appointment',
      operation: 'DELETE',
      localId: localId,
      payloadJson: jsonEncode({'local_id': localId}),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> updateStatus(String localId, String status) async {
    await _db.appointmentDao.updateStatus(localId, status);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'appointment',
      operation: 'UPDATE',
      localId: localId,
      payloadJson: jsonEncode({'status': status}),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> assignToken(String localId, int tokenNumber) async {
    await _db.appointmentDao.assignToken(localId, tokenNumber);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'appointment',
      operation: 'UPDATE',
      localId: localId,
      payloadJson: jsonEncode({'token_number': tokenNumber}),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  Map<String, dynamic> _createToJson(CreateAppointmentRequest req) => {
        'patient_id': req.patientId,
        'doctor_id': req.doctorId,
        if (req.chamberId != null) 'chamber_id': req.chamberId,
        'scheduled_at': req.scheduledAt,
        'appointment_type': req.appointmentType,
        if (req.notes.isNotEmpty) 'notes': req.notes,
      };

  Map<String, dynamic> _walkInToJson(WalkInRequest req) => {
        'patient_id': req.patientId,
        'doctor_id': req.doctorId,
        if (req.chamberId != null) 'chamber_id': req.chamberId,
        if (req.notes.isNotEmpty) 'notes': req.notes,
      };

  Map<String, dynamic> _updateToJson(UpdateAppointmentRequest req) => {
        if (req.chamberId != null) 'chamber_id': req.chamberId,
        'scheduled_at': req.scheduledAt,
        'appointment_type': req.appointmentType,
        if (req.notes.isNotEmpty) 'notes': req.notes,
      };
}
