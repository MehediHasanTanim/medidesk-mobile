import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/billing_models.dart';

abstract final class BillingMapper {
  // ── Row → Domain model ────────────────────────────────────────────────

  static Invoice fromRow(InvoiceRow row) => Invoice(
        id: row.id,
        invoiceNumber: row.invoiceNumber,
        patientId: row.patientId,
        consultationId: row.consultationId,
        discountPercent: row.discountPercent,
        status: row.status,
        createdById: row.createdById,
        createdAt: row.createdAt,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  static InvoiceItem itemFromRow(InvoiceItemRow row) => InvoiceItem(
        id: row.id,
        invoiceId: row.invoiceId,
        description: row.description,
        quantity: row.quantity,
        unitPrice: row.unitPrice,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  static Payment paymentFromRow(PaymentRow row) => Payment(
        id: row.id,
        invoiceId: row.invoiceId,
        amount: row.amount,
        method: row.method,
        transactionRef: row.transactionRef,
        paidAt: row.paidAt,
        recordedById: row.recordedById,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  // ── Domain request → Drift companion ─────────────────────────────────

  static InvoicesCompanion toCreateCompanion(
    String localId,
    CreateInvoiceRequest req,
  ) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return InvoicesCompanion.insert(
      id: localId,
      patientId: req.patientId,
      consultationId: Value(req.consultationId),
      discountPercent: Value(req.discountPercent),
      status: const Value('draft'),
      createdAt: nowIso,
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static InvoiceItemsCompanion itemToCompanion(
    String itemLocalId,
    String invoiceLocalId,
    InvoiceItemInput item,
  ) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return InvoiceItemsCompanion.insert(
      id: itemLocalId,
      invoiceId: invoiceLocalId,
      description: item.description,
      quantity: Value(item.quantity),
      unitPrice: item.unitPrice,
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static PaymentsCompanion paymentToCompanion(
    String localId,
    RecordPaymentRequest req,
  ) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    return PaymentsCompanion.insert(
      id: localId,
      invoiceId: req.invoiceLocalId,
      amount: req.amount,
      method: req.method,
      transactionRef: Value(req.transactionRef),
      paidAt: nowIso,
      recordedById: Value(req.recordedById),
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }
}
