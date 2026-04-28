import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/appointment_model.dart';

abstract final class AppointmentMapper {
  static Appointment fromRow(AppointmentRow row) => Appointment(
        id: row.id,
        patientId: row.patientId,
        doctorId: row.doctorId,
        chamberId: row.chamberId,
        scheduledAt: row.scheduledAt,
        appointmentType: row.appointmentType,
        status: row.status,
        tokenNumber: row.tokenNumber,
        notes: row.notes,
        createdById: row.createdById,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  static AppointmentsCompanion toCreateCompanion(
    String localId,
    CreateAppointmentRequest req,
  ) {
    final now = DateTime.now();
    final nowIso = now.toUtc().toIso8601String();
    final nowMs = now.millisecondsSinceEpoch;
    return AppointmentsCompanion.insert(
      id: localId,
      patientId: req.patientId,
      doctorId: req.doctorId,
      chamberId: Value(req.chamberId),
      scheduledAt: req.scheduledAt,
      appointmentType: req.appointmentType,
      status: const Value('scheduled'),
      notes: Value(req.notes),
      createdAt: nowIso,
      updatedAt: nowIso,
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static AppointmentsCompanion toWalkInCompanion(
    String localId,
    WalkInRequest req,
  ) {
    final now = DateTime.now();
    final nowIso = now.toUtc().toIso8601String();
    final nowMs = now.millisecondsSinceEpoch;
    return AppointmentsCompanion.insert(
      id: localId,
      patientId: req.patientId,
      doctorId: req.doctorId,
      chamberId: Value(req.chamberId),
      scheduledAt: nowIso,
      appointmentType: 'walk_in',
      status: const Value('in_queue'),
      notes: Value(req.notes),
      createdAt: nowIso,
      updatedAt: nowIso,
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static AppointmentsCompanion toUpdateCompanion(
    UpdateAppointmentRequest req,
  ) {
    final now = DateTime.now();
    final nowIso = now.toUtc().toIso8601String();
    final nowMs = now.millisecondsSinceEpoch;
    return AppointmentsCompanion(
      id: Value(req.localId),
      chamberId: Value(req.chamberId),
      scheduledAt: Value(req.scheduledAt),
      appointmentType: Value(req.appointmentType),
      notes: Value(req.notes),
      updatedAt: Value(nowIso),
      lastModified: Value(nowMs),
      syncStatus: const Value('pending'),
    );
  }
}
