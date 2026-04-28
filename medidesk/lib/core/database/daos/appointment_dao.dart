import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/appointment_tables.dart';

part 'appointment_dao.g.dart';

@DriftAccessor(tables: [Appointments])
class AppointmentDao extends DatabaseAccessor<AppDatabase>
    with _$AppointmentDaoMixin {
  AppointmentDao(super.db);

  Stream<List<AppointmentRow>> watchByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    return (select(appointments)
          ..where(
            (t) =>
                t.isDeleted.equals(0) &
                t.scheduledAt.isBiggerOrEqualValue(dayStart) &
                t.scheduledAt.isSmallerOrEqualValue(dayEnd),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Stream<List<AppointmentRow>> watchByPatient(String patientLocalId) =>
      (select(appointments)
            ..where(
              (t) =>
                  t.patientId.equals(patientLocalId) & t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
          .watch();

  Stream<List<AppointmentRow>> watchByDoctor(String doctorId) =>
      (select(appointments)
            ..where(
              (t) => t.doctorId.equals(doctorId) & t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
          .watch();

  Stream<List<AppointmentRow>> watchQueue(String chamberId, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    return (select(appointments)
          ..where(
            (t) =>
                t.chamberId.equals(chamberId) &
                t.isDeleted.equals(0) &
                t.scheduledAt.isBiggerOrEqualValue(dayStart) &
                t.scheduledAt.isSmallerOrEqualValue(dayEnd) &
                (t.status.equals('in_queue') | t.status.equals('in_progress')),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.tokenNumber),
          ]))
        .watch();
  }

  Future<AppointmentRow?> getById(String localId) =>
      (select(appointments)
            ..where((t) => t.id.equals(localId) & t.isDeleted.equals(0)))
          .getSingleOrNull();

  Future<void> upsertAll(List<AppointmentsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(appointments, rows);
    });
  }

  Future<void> updateStatus(String localId, String status) {
    final now = DateTime.now().toIso8601String();
    return (update(appointments)..where((t) => t.id.equals(localId))).write(
      AppointmentsCompanion(
        status: Value(status),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> assignToken(String localId, int tokenNumber) {
    final now = DateTime.now().toIso8601String();
    return (update(appointments)..where((t) => t.id.equals(localId))).write(
      AppointmentsCompanion(
        tokenNumber: Value(tokenNumber),
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
    return (update(appointments)..where((t) => t.id.equals(localId))).write(
      AppointmentsCompanion(
        syncStatus: Value(syncStatus),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }

  Future<void> insertAppointment(AppointmentsCompanion companion) =>
      into(appointments).insert(companion);

  Future<void> updateAppointment(AppointmentsCompanion companion) =>
      (update(appointments)..where((t) => t.id.equals(companion.id.value)))
          .write(companion);

  Future<void> softDelete(String localId) {
    final now = DateTime.now().toIso8601String();
    return (update(appointments)..where((t) => t.id.equals(localId))).write(
      AppointmentsCompanion(
        isDeleted: const Value(1),
        deletedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<AppointmentRow?> getByServerId(String serverId) =>
      (select(appointments)..where((t) => t.serverId.equals(serverId)))
          .getSingleOrNull();

  Stream<List<AppointmentRow>> watchTodayQueue(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    return (select(appointments)
          ..where(
            (t) =>
                t.isDeleted.equals(0) &
                t.scheduledAt.isBiggerOrEqualValue(dayStart) &
                t.scheduledAt.isSmallerOrEqualValue(dayEnd) &
                (t.status.equals('in_queue') | t.status.equals('in_progress')),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.tokenNumber)]))
        .watch();
  }
}
