import 'package:drift/drift.dart';

@DataClassName('PatientRow')
class Patients extends Table {
  // Local UUID — device-generated
  TextColumn get id => text()();
  // Server-assigned readable ID like "P-00123"
  TextColumn get patientId => text().nullable()();
  TextColumn get fullName => text()();
  TextColumn get phone => text()();
  TextColumn get gender => text()(); // M | F | O
  TextColumn get address => text()();
  TextColumn get dateOfBirth => text().nullable()(); // "YYYY-MM-DD"
  TextColumn get email => text().nullable()();
  TextColumn get nationalId => text().nullable()();
  IntColumn get ageYears => integer().nullable()();
  TextColumn get allergies => text().withDefault(const Constant('[]'))(); // JSONB
  TextColumn get chronicDiseases => text().withDefault(const Constant('[]'))(); // JSONB
  TextColumn get familyHistory => text().withDefault(const Constant(''))();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get lastModified => integer()(); // unix ms

  // Sync columns
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PatientNoteRow')
class PatientNotes extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get content => text()();
  TextColumn get createdById => text().nullable()();
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
