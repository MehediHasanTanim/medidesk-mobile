import 'package:drift/drift.dart';

@DataClassName('AppointmentRow')
class Appointments extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get doctorId => text()();
  TextColumn get chamberId => text().nullable()();
  TextColumn get scheduledAt => text()(); // ISO8601 UTC
  TextColumn get appointmentType => text()(); // new | follow_up | walk_in
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  IntColumn get tokenNumber => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get createdById => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get lastModified => integer()();

  // Sync columns
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
