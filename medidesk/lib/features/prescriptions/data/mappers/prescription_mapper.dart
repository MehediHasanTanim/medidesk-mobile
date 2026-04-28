import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../models/prescription_models.dart';

abstract final class PrescriptionMapper {
  static const _uuid = Uuid();

  // ── Row → Domain model ────────────────────────────────────────────────

  static Prescription fromRow(PrescriptionRow row) => Prescription(
        id: row.id,
        consultationId: row.consultationId,
        patientId: row.patientId,
        prescribedById: row.prescribedById,
        approvedById: row.approvedById,
        status: row.status,
        followUpDate: row.followUpDate,
        pdfPath: row.pdfPath,
        createdAt: row.createdAt,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  static PrescriptionItem itemFromRow(PrescriptionItemRow row) =>
      PrescriptionItem(
        id: row.id,
        prescriptionId: row.prescriptionId,
        medicineId: row.medicineId,
        medicineName: row.medicineName,
        morning: row.morning,
        afternoon: row.afternoon,
        evening: row.evening,
        durationDays: row.durationDays,
        route: row.route,
        instructions: row.instructions,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  // ── Domain request → Drift companion ─────────────────────────────────

  static PrescriptionsCompanion toCreateCompanion(
    String localId,
    CreatePrescriptionRequest req,
  ) {
    final now = DateTime.now();
    final nowIso = now.toUtc().toIso8601String();
    final nowMs = now.millisecondsSinceEpoch;
    return PrescriptionsCompanion.insert(
      id: localId,
      consultationId: req.consultationId,
      patientId: req.patientId,
      prescribedById: req.prescribedById,
      followUpDate: Value(req.followUpDate),
      createdAt: nowIso,
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static PrescriptionItemsCompanion toItemCompanion(
    String itemLocalId,
    String prescriptionLocalId,
    PrescriptionItemInput input,
  ) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return PrescriptionItemsCompanion.insert(
      id: itemLocalId,
      prescriptionId: prescriptionLocalId,
      medicineId: input.medicineId,
      medicineName: input.medicineName,
      morning: input.morning,
      afternoon: input.afternoon,
      evening: input.evening,
      durationDays: input.durationDays,
      route: Value(input.route),
      instructions: Value(input.instructions),
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static String generateItemId() => _uuid.v4();
}
