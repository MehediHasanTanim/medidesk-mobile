import 'package:drift/drift.dart';

@DataClassName('ChamberRow')
class Chambers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get phone => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get role => text()(); // UserRole enum stored as string
  TextColumn get supervisorId => text().nullable()();
  TextColumn get username => text()();
  TextColumn get email => text().nullable()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get dateJoined => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SpecialityRow')
class Specialities extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DoctorProfileRow')
class DoctorProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get specialityId => text()();
  TextColumn get qualifications => text()();
  TextColumn get bio => text().withDefault(const Constant(''))();
  RealColumn get consultationFee => real().nullable()();
  IntColumn get experienceYears => integer().nullable()();
  IntColumn get isAvailable => integer().withDefault(const Constant(1))();
  TextColumn get visitDays => text().withDefault(const Constant('[]'))(); // JSONB
  TextColumn get visitTimeStart => text().nullable()(); // "HH:mm"
  TextColumn get visitTimeEnd => text().nullable()(); // "HH:mm"

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GenericMedicineRow')
class GenericMedicines extends Table {
  TextColumn get id => text()();
  TextColumn get genericName => text()();
  TextColumn get drugClass => text()();
  TextColumn get therapeuticClass => text().withDefault(const Constant(''))();
  TextColumn get indications => text().withDefault(const Constant(''))();
  TextColumn get contraindications => text().withDefault(const Constant('[]'))(); // JSONB
  TextColumn get sideEffects => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BrandMedicineRow')
class BrandMedicines extends Table {
  TextColumn get id => text()();
  TextColumn get genericId => text()();
  TextColumn get brandName => text()();
  TextColumn get manufacturer => text()();
  TextColumn get strength => text()();
  TextColumn get form => text()(); // MedicineForm enum
  RealColumn get mrp => real().nullable()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
