import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/lookup_tables.dart';

part 'doctor_profile_dao.g.dart';

@DriftAccessor(tables: [DoctorProfiles])
class DoctorProfileDao extends DatabaseAccessor<AppDatabase>
    with _$DoctorProfileDaoMixin {
  DoctorProfileDao(super.db);

  Stream<List<DoctorProfileRow>> watchAll() =>
      (select(doctorProfiles)..where((t) => t.isAvailable.equals(1))).watch();

  Future<DoctorProfileRow?> getByUserId(String userId) =>
      (select(doctorProfiles)..where((t) => t.userId.equals(userId)))
          .getSingleOrNull();

  Future<void> upsertAll(List<DoctorProfilesCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(doctorProfiles, rows);
    });
  }
}
