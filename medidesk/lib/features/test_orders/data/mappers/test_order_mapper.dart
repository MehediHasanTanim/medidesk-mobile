import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/test_order_models.dart';

abstract final class TestOrderMapper {
  // ── Row → Domain model ────────────────────────────────────────────────

  static TestOrder fromRow(TestOrderRow row) => TestOrder(
        id: row.id,
        consultationId: row.consultationId,
        patientId: row.patientId,
        testName: row.testName,
        labName: row.labName,
        notes: row.notes,
        orderedById: row.orderedById,
        orderedAt: row.orderedAt,
        isCompleted: row.isCompleted == 1,
        completedAt: row.completedAt,
        approvalStatus: row.approvalStatus,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  // ── Request → Drift companion (bulk create inserts individual rows) ────

  static TestOrdersCompanion toCreateCompanion({
    required String localId,
    required String consultationLocalId,
    required String patientId,
    required TestOrderInput input,
  }) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return TestOrdersCompanion.insert(
      id: localId,
      consultationId: consultationLocalId,
      patientId: patientId,
      testName: input.testName,
      labName: Value(input.labName),
      notes: Value(input.notes),
      orderedAt: nowIso,
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static TestOrdersCompanion toUpdateCompanion(UpdateTestOrderRequest req) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return TestOrdersCompanion(
      id: Value(req.localId),
      testName: req.testName != null ? Value(req.testName!) : const Value.absent(),
      labName: req.labName != null ? Value(req.labName!) : const Value.absent(),
      notes: req.notes != null ? Value(req.notes!) : const Value.absent(),
      isCompleted: req.isCompleted != null
          ? Value(req.isCompleted! ? 1 : 0)
          : const Value.absent(),
      completedAt:
          req.completedAt != null ? Value(req.completedAt) : const Value.absent(),
      lastModified: Value(nowMs),
      syncStatus: const Value('pending'),
    );
  }
}
