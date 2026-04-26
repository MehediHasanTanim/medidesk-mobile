import 'package:drift/drift.dart';

@DataClassName('PrescriptionRow')
class Prescriptions extends Table {
  TextColumn get id => text()();
  TextColumn get consultationId => text()();
  TextColumn get patientId => text()();
  TextColumn get prescribedById => text()();
  TextColumn get approvedById => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get followUpDate => text().nullable()(); // "YYYY-MM-DD"
  TextColumn get pdfPath => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text()();
  IntColumn get lastModified => integer()();

  // Sync columns
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PrescriptionItemRow')
class PrescriptionItems extends Table {
  TextColumn get id => text()();
  TextColumn get prescriptionId => text()();
  TextColumn get medicineId => text()();
  // Snapshot of brand name at time of prescribing — never updated from catalogue
  TextColumn get medicineName => text()();
  TextColumn get morning => text()();
  TextColumn get afternoon => text()();
  TextColumn get evening => text()();
  IntColumn get durationDays => integer()();
  TextColumn get route => text().withDefault(const Constant('oral'))();
  TextColumn get instructions => text().withDefault(const Constant(''))();
  IntColumn get lastModified => integer()();

  // Sync columns
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
