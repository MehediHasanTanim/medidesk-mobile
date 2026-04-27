import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/billing_tables.dart';

part 'invoice_dao.g.dart';

@DriftAccessor(tables: [Invoices, InvoiceItems, Payments])
class InvoiceDao extends DatabaseAccessor<AppDatabase>
    with _$InvoiceDaoMixin {
  InvoiceDao(super.db);

  Stream<List<InvoiceRow>> watchByPatient(String patientLocalId) =>
      (select(invoices)
            ..where(
              (t) =>
                  t.patientId.equals(patientLocalId) & t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<InvoiceItemRow>> watchItems(String invoiceLocalId) =>
      (select(invoiceItems)
            ..where(
              (t) =>
                  t.invoiceId.equals(invoiceLocalId) & t.isDeleted.equals(0),
            ))
          .watch();

  Stream<List<PaymentRow>> watchPayments(String invoiceLocalId) =>
      (select(payments)
            ..where(
              (t) =>
                  t.invoiceId.equals(invoiceLocalId) & t.isDeleted.equals(0),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.paidAt)]))
          .watch();

  Future<InvoiceRow?> getById(String localId) =>
      (select(invoices)
            ..where((t) => t.id.equals(localId) & t.isDeleted.equals(0)))
          .getSingleOrNull();

  Future<void> upsertInvoice(InvoicesCompanion row) =>
      into(invoices).insertOnConflictUpdate(row);

  Future<void> upsertAllInvoices(List<InvoicesCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(invoices, rows);
    });
  }

  Future<void> replaceItems(
    String invoiceLocalId,
    List<InvoiceItemsCompanion> items,
  ) async {
    await transaction(() async {
      await (delete(invoiceItems)
            ..where((t) => t.invoiceId.equals(invoiceLocalId)))
          .go();
      await batch((b) {
        b.insertAll(invoiceItems, items);
      });
    });
  }

  Future<void> insertPayment(PaymentsCompanion row) =>
      into(payments).insert(row);

  Future<void> upsertAllItems(List<InvoiceItemsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(invoiceItems, rows);
    });
  }

  Future<void> upsertAllPayments(List<PaymentsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(payments, rows);
    });
  }

  Future<void> updateSyncStatus(
    String localId,
    String syncStatus, {
    String? serverId,
  }) {
    return (update(invoices)..where((t) => t.id.equals(localId))).write(
      InvoicesCompanion(
        syncStatus: Value(syncStatus),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }

  Future<void> updatePaymentSyncStatus(
    String localId,
    String syncStatus, {
    String? serverId,
  }) {
    return (update(payments)..where((t) => t.id.equals(localId))).write(
      PaymentsCompanion(
        syncStatus: Value(syncStatus),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
      ),
    );
  }
}
