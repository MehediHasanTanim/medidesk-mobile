import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/consultation_tables.dart';

part 'consultation_dao.g.dart';

@DriftAccessor(tables: [Consultations])
class ConsultationDao extends DatabaseAccessor<AppDatabase>
    with _$ConsultationDaoMixin {
  ConsultationDao(super.db);

  Stream<ConsultationRow?> watchByAppointment(String appointmentLocalId) =>
      (select(consultations)
            ..where(
              (t) =>
                  t.appointmentId.equals(appointmentLocalId) &
                  t.isDeleted.equals(0),
            ))
          .watchSingleOrNull();

  Stream<List<ConsultationRow>> watchByPatient(String patientLocalId) =>
      (select(consultations)
            ..where(
              (t) =>
                  t.patientId.equals(patientLocalId) & t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<ConsultationRow?> getById(String localId) =>
      (select(consultations)..where((t) => t.id.equals(localId)))
          .getSingleOrNull();

  Future<void> upsertConsultation(ConsultationsCompanion row) =>
      into(consultations).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<ConsultationsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(consultations, rows);
    });
  }

  Future<void> updateSyncStatus(
    String localId,
    String syncStatus, {
    String? serverId,
  }) {
    return (update(consultations)..where((t) => t.id.equals(localId))).write(
      ConsultationsCompanion(
        syncStatus: Value(syncStatus),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }
}
