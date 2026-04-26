import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/lookup_tables.dart';

part 'speciality_dao.g.dart';

@DriftAccessor(tables: [Specialities])
class SpecialityDao extends DatabaseAccessor<AppDatabase>
    with _$SpecialityDaoMixin {
  SpecialityDao(super.db);

  Stream<List<SpecialityRow>> watchAll() =>
      (select(specialities)..where((t) => t.isActive.equals(1))).watch();

  Future<void> upsertAll(List<SpecialitiesCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(specialities, rows);
    });
  }
}
