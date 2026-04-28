import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/consultation_models.dart';

abstract final class ConsultationMapper {
  static Consultation fromRow(ConsultationRow row) => Consultation(
        id: row.id,
        appointmentId: row.appointmentId,
        patientId: row.patientId,
        doctorId: row.doctorId,
        chiefComplaints: row.chiefComplaints,
        clinicalFindings: row.clinicalFindings,
        diagnosis: row.diagnosis,
        notes: row.notes,
        bpSystolic: row.bpSystolic,
        bpDiastolic: row.bpDiastolic,
        pulse: row.pulse,
        temperature: row.temperature,
        weight: row.weight,
        height: row.height,
        spo2: row.spo2,
        isDraft: row.isDraft == 1,
        createdAt: row.createdAt,
        completedAt: row.completedAt,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  static ConsultationsCompanion toCreateCompanion(
    String localId,
    StartConsultationRequest req,
  ) {
    final now = DateTime.now();
    final nowIso = now.toUtc().toIso8601String();
    final nowMs = now.millisecondsSinceEpoch;
    return ConsultationsCompanion.insert(
      id: localId,
      appointmentId: req.appointmentId,
      patientId: req.patientId,
      doctorId: req.doctorId,
      chiefComplaints: req.chiefComplaints,
      isDraft: const Value(1),
      createdAt: nowIso,
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static ConsultationsCompanion toUpdateCompanion(
    UpdateConsultationRequest req,
  ) {
    final now = DateTime.now();
    return ConsultationsCompanion(
      id: Value(req.localId),
      chiefComplaints: req.chiefComplaints != null
          ? Value(req.chiefComplaints!)
          : const Value.absent(),
      clinicalFindings: req.clinicalFindings != null
          ? Value(req.clinicalFindings!)
          : const Value.absent(),
      diagnosis: req.diagnosis != null
          ? Value(req.diagnosis!)
          : const Value.absent(),
      notes: req.notes != null ? Value(req.notes!) : const Value.absent(),
      lastModified: Value(now.millisecondsSinceEpoch),
      syncStatus: const Value('pending'),
    );
  }

  static ConsultationsCompanion toVitalsCompanion(UpdateVitalsRequest req) {
    final now = DateTime.now();
    return ConsultationsCompanion(
      id: Value(req.localId),
      bpSystolic: Value(req.bpSystolic),
      bpDiastolic: Value(req.bpDiastolic),
      pulse: Value(req.pulse),
      temperature: Value(req.temperature),
      weight: Value(req.weight),
      height: Value(req.height),
      spo2: Value(req.spo2),
      lastModified: Value(now.millisecondsSinceEpoch),
      syncStatus: const Value('pending'),
    );
  }
}
