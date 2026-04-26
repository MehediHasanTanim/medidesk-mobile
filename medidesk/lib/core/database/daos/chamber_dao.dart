import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/lookup_tables.dart';

part 'chamber_dao.g.dart';

@DriftAccessor(tables: [Chambers])
class ChamberDao extends DatabaseAccessor<AppDatabase> with _$ChamberDaoMixin {
  ChamberDao(super.db);

  Stream<List<ChamberRow>> watchAll() =>
      (select(chambers)..where((t) => t.isActive.equals(1))).watch();

  Future<ChamberRow?> getById(String id) =>
      (select(chambers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertAll(List<ChambersCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(chambers, rows);
    });
  }
}
