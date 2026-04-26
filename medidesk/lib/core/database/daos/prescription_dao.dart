import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/prescription_tables.dart';

part 'prescription_dao.g.dart';

@DriftAccessor(tables: [Prescriptions, PrescriptionItems])
class PrescriptionDao extends DatabaseAccessor<AppDatabase>
    with _$PrescriptionDaoMixin {
  PrescriptionDao(super.db);

  Stream<PrescriptionRow?> watchByConsultation(String consultationLocalId) =>
      (select(prescriptions)
            ..where(
              (t) =>
                  t.consultationId.equals(consultationLocalId) &
                  t.isDeleted.equals(0),
            ))
          .watchSingleOrNull();

  Stream<List<PrescriptionRow>> watchByPatient(String patientLocalId) =>
      (select(prescriptions)
            ..where(
              (t) =>
                  t.patientId.equals(patientLocalId) & t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> upsertPrescription(PrescriptionsCompanion row) =>
      into(prescriptions).insertOnConflictUpdate(row);

  Future<void> upsertAllPrescriptions(List<PrescriptionsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(prescriptions, rows);
    });
  }

  Future<void> updateSyncStatus(
    String localId,
    String syncStatus, {
    String? serverId,
  }) {
    return (update(prescriptions)..where((t) => t.id.equals(localId))).write(
      PrescriptionsCompanion(
        syncStatus: Value(syncStatus),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }

  Stream<List<PrescriptionItemRow>> watchByPrescription(
    String prescriptionLocalId,
  ) =>
      (select(prescriptionItems)
            ..where(
              (t) =>
                  t.prescriptionId.equals(prescriptionLocalId) &
                  t.isDeleted.equals(0),
            ))
          .watch();

  Future<void> replaceItems(
    String prescriptionLocalId,
    List<PrescriptionItemsCompanion> items,
  ) async {
    await transaction(() async {
      await (delete(prescriptionItems)
            ..where((t) => t.prescriptionId.equals(prescriptionLocalId)))
          .go();
      await batch((b) {
        b.insertAll(prescriptionItems, items);
      });
    });
  }

  Future<void> upsertAll(List<PrescriptionItemsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(prescriptionItems, rows);
    });
  }
}
