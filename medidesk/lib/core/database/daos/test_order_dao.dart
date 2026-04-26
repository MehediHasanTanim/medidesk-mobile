import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/test_order_tables.dart';

part 'test_order_dao.g.dart';

@DriftAccessor(tables: [TestOrders])
class TestOrderDao extends DatabaseAccessor<AppDatabase>
    with _$TestOrderDaoMixin {
  TestOrderDao(super.db);

  Stream<List<TestOrderRow>> watchByConsultation(String consultationLocalId) =>
      (select(testOrders)
            ..where(
              (t) =>
                  t.consultationId.equals(consultationLocalId) &
                  t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.orderedAt)]))
          .watch();

  Stream<List<TestOrderRow>> watchByPatient(String patientLocalId) =>
      (select(testOrders)
            ..where(
              (t) =>
                  t.patientId.equals(patientLocalId) & t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.orderedAt)]))
          .watch();

  Future<void> upsertAll(List<TestOrdersCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(testOrders, rows);
    });
  }

  Future<void> insertTestOrder(TestOrdersCompanion row) =>
      into(testOrders).insert(row);

  Future<void> updateSyncStatus(
    String localId,
    String syncStatus, {
    String? serverId,
  }) {
    return (update(testOrders)..where((t) => t.id.equals(localId))).write(
      TestOrdersCompanion(
        syncStatus: Value(syncStatus),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }
}
