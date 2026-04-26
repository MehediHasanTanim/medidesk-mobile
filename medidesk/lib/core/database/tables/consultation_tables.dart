import 'package:drift/drift.dart';

@DataClassName('ConsultationRow')
class Consultations extends Table {
  TextColumn get id => text()();
  TextColumn get appointmentId => text()();
  TextColumn get patientId => text()();
  TextColumn get doctorId => text()();
  TextColumn get chiefComplaints => text()();
  TextColumn get clinicalFindings => text().withDefault(const Constant(''))();
  TextColumn get diagnosis => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get bpSystolic => integer().nullable()();
  IntColumn get bpDiastolic => integer().nullable()();
  IntColumn get pulse => integer().nullable()();
  RealColumn get temperature => real().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get height => real().nullable()();
  IntColumn get spo2 => integer().nullable()();
  IntColumn get isDraft => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();
  TextColumn get completedAt => text().nullable()();
  IntColumn get lastModified => integer()();

  // Sync columns
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
