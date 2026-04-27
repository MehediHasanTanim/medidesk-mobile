import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/patient_tables.dart';

part 'patient_dao.g.dart';

@DriftAccessor(tables: [Patients, PatientNotes])
class PatientDao extends DatabaseAccessor<AppDatabase> with _$PatientDaoMixin {
  PatientDao(super.db);

  Stream<List<PatientRow>> watchAll({String? searchQuery}) {
    final q = (select(patients)
      ..where((t) => t.isDeleted.equals(0))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final like = '%${searchQuery.toLowerCase()}%';
      return (select(patients)
            ..where(
              (t) =>
                  t.isDeleted.equals(0) &
                  (t.fullName.lower().like(like) |
                      t.phone.like(like) |
                      t.patientId.lower().like(like)),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
          .watch();
    }
    return q.watch();
  }

  Future<PatientRow?> getById(String localId) =>
      (select(patients)
            ..where((t) => t.id.equals(localId) & t.isDeleted.equals(0)))
          .getSingleOrNull();

  Future<PatientRow?> getByServerId(String serverId) =>
      (select(patients)
            ..where(
              (t) => t.serverId.equals(serverId) & t.isDeleted.equals(0),
            ))
          .getSingleOrNull();

  Future<void> insertPatient(PatientsCompanion row) =>
      into(patients).insert(row);

  Future<void> updatePatient(PatientsCompanion row) =>
      (update(patients)..where((t) => t.id.equals(row.id.value)))
          .write(row);

  Future<void> upsertAll(List<PatientsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(patients, rows);
    });
  }

  Future<void> softDelete(String localId) {
    final now = DateTime.now().toIso8601String();
    return (update(patients)..where((t) => t.id.equals(localId))).write(
      PatientsCompanion(
        isDeleted: const Value(1),
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> updateSyncStatus(
    String localId,
    String syncStatus, {
    String? serverId,
  }) {
    return (update(patients)..where((t) => t.id.equals(localId))).write(
      PatientsCompanion(
        syncStatus: Value(syncStatus),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }

  // --- PatientNotes ---

  Stream<List<PatientNoteRow>> watchByPatient(String patientLocalId) =>
      (select(patientNotes)
            ..where(
              (t) =>
                  t.patientId.equals(patientLocalId) &
                  t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> insertNote(PatientNotesCompanion row) =>
      into(patientNotes).insert(row);

  Future<void> upsertAllNotes(List<PatientNotesCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(patientNotes, rows);
    });
  }

  Future<void> updateNoteSyncStatus(
    String localId,
    String syncStatus, {
    String? serverId,
  }) {
    return (update(patientNotes)..where((t) => t.id.equals(localId))).write(
      PatientNotesCompanion(
        syncStatus: Value(syncStatus),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }
}
