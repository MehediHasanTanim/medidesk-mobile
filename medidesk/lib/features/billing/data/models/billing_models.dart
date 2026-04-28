import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_models.freezed.dart';
part 'billing_models.g.dart';

// ── Domain models ─────────────────────────────────────────────────────────

@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    String? invoiceNumber,
    required String patientId,
    String? consultationId,
    @Default(0.0) double discountPercent,
    @Default('draft') String status,
    String? createdById,
    required String createdAt,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}

@freezed
class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String invoiceId,
    required String description,
    @Default(1) int quantity,
    required double unitPrice,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);
}

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String invoiceId,
    required double amount,
    required String method,
    @Default('') String transactionRef,
    required String paidAt,
    String? recordedById,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}

// ── Computed summary (§9.4) — not stored, derived in UI layer ────────────

class InvoiceSummary {
  const InvoiceSummary({
    required this.subtotal,
    required this.total,
    required this.paid,
    required this.balance,
  });

  final double subtotal;
  final double total;
  final double paid;
  final double balance;

  factory InvoiceSummary.compute({
    required List<InvoiceItem> items,
    required List<Payment> payments,
    required double discountPercent,
  }) {
    final subtotal = items.fold(
      0.0,
      (sum, item) => sum + item.quantity * item.unitPrice,
    );
    final total = subtotal * (1 - discountPercent / 100);
    final paid = payments.fold(0.0, (sum, p) => sum + p.amount);
    return InvoiceSummary(
      subtotal: subtotal,
      total: total,
      paid: paid,
      balance: total - paid,
    );
  }
}

// ── Online-only: income report ────────────────────────────────────────────

class IncomeReport {
  const IncomeReport({
    required this.fromDate,
    required this.toDate,
    required this.totalRevenue,
    required this.totalPaid,
    required this.totalPending,
    required this.invoiceCount,
    required this.dataPoints,
  });

  final String fromDate;
  final String toDate;
  final double totalRevenue;
  final double totalPaid;
  final double totalPending;
  final int invoiceCount;
  final List<IncomeDataPoint> dataPoints;

  factory IncomeReport.fromJson(Map<String, dynamic> json) => IncomeReport(
        fromDate: json['from_date'] as String? ?? '',
        toDate: json['to_date'] as String? ?? '',
        totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
        totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
        totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0.0,
        invoiceCount: json['invoice_count'] as int? ?? 0,
        dataPoints: ((json['data_points'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(IncomeDataPoint.fromJson)
            .toList(),
      );
}

class IncomeDataPoint {
  const IncomeDataPoint({
    required this.date,
    required this.revenue,
    required this.paid,
  });

  final String date;
  final double revenue;
  final double paid;

  factory IncomeDataPoint.fromJson(Map<String, dynamic> json) =>
      IncomeDataPoint(
        date: json['date'] as String? ?? '',
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
        paid: (json['paid'] as num?)?.toDouble() ?? 0.0,
      );
}

// ── Request models ────────────────────────────────────────────────────────

@freezed
class InvoiceItemInput with _$InvoiceItemInput {
  const factory InvoiceItemInput({
    required String description,
    @Default(1) int quantity,
    required double unitPrice,
  }) = _InvoiceItemInput;

  factory InvoiceItemInput.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemInputFromJson(json);
}

@freezed
class CreateInvoiceRequest with _$CreateInvoiceRequest {
  const factory CreateInvoiceRequest({
    required String patientId,
    String? consultationId,
    required List<InvoiceItemInput> items,
    @Default(0.0) double discountPercent,
  }) = _CreateInvoiceRequest;

  factory CreateInvoiceRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateInvoiceRequestFromJson(json);
}

@freezed
class RecordPaymentRequest with _$RecordPaymentRequest {
  const factory RecordPaymentRequest({
    required String invoiceLocalId,
    required double amount,
    required String method,
    @Default('') String transactionRef,
    String? recordedById,
  }) = _RecordPaymentRequest;

  factory RecordPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$RecordPaymentRequestFromJson(json);
}
