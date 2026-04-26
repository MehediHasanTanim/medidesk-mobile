import 'package:drift/drift.dart';

@DataClassName('InvoiceRow')
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNumber => text().nullable()(); // "INV-2024-00042" from server
  TextColumn get patientId => text()();
  TextColumn get consultationId => text().nullable()();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
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

@DataClassName('InvoiceItemRow')
class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text()();
  TextColumn get description => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get unitPrice => real()();
  IntColumn get lastModified => integer()();

  // Sync columns
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text()();
  RealColumn get amount => real()();
  TextColumn get method => text()(); // cash | bkash | nagad | card
  TextColumn get transactionRef => text().withDefault(const Constant(''))();
  TextColumn get paidAt => text()();
  TextColumn get recordedById => text().nullable()();
  IntColumn get lastModified => integer()();

  // Sync columns
  TextColumn get serverId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
