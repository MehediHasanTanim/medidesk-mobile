import 'package:drift/drift.dart';

@DataClassName('TestOrderRow')
class TestOrders extends Table {
  TextColumn get id => text()();
  TextColumn get consultationId => text()();
  TextColumn get patientId => text()();
  TextColumn get testName => text()();
  TextColumn get labName => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get orderedById => text().nullable()();
  TextColumn get orderedAt => text()();
  IntColumn get isCompleted => integer().withDefault(const Constant(0))();
  TextColumn get completedAt => text().nullable()();
  TextColumn get approvalStatus =>
      text().withDefault(const Constant('approved'))();
  IntColumn get lastModified => integer()();

  // Sync columns
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
