import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/lookup_tables.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Stream<List<UserRow>> watchAll() =>
      (select(users)..where((t) => t.isActive.equals(1))).watch();

  Future<UserRow?> getById(String id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<UserRow>> getDoctors() =>
      (select(users)
            ..where(
              (t) =>
                  (t.role.equals('doctor') |
                      t.role.equals('assistant_doctor')) &
                  t.isActive.equals(1),
            ))
          .get();

  Future<void> upsertAll(List<UsersCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(users, rows);
    });
  }
}
