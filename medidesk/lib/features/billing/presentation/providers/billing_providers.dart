import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/infrastructure_providers.dart';
import '../../../../shared/providers/sync_status_provider.dart';
import '../../data/models/billing_models.dart';
import '../../data/repositories/billing_repository.dart';

part 'billing_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(
    db: ref.watch(appDatabaseProvider),
    syncService: ref.watch(syncServiceProvider),
    dio: ref.watch(dioProvider),
  );
});

// ── Read providers ────────────────────────────────────────────────────────

/// Reactive list of all invoices — rebuilds when Drift emits.
@riverpod
Stream<List<Invoice>> invoiceList(InvoiceListRef ref) {
  return ref.watch(billingRepositoryProvider).watchAll();
}

/// Reactive list of invoices for a specific patient.
@riverpod
Stream<List<Invoice>> invoicesByPatient(
  InvoicesByPatientRef ref,
  String patientLocalId,
) {
  return ref
      .watch(billingRepositoryProvider)
      .watchByPatient(patientLocalId);
}

/// Single-shot invoice fetch for display.
@riverpod
Future<Invoice?> invoiceDetail(InvoiceDetailRef ref, String localId) {
  return ref.watch(billingRepositoryProvider).getById(localId);
}

/// Reactive invoice items for an invoice.
@riverpod
Stream<List<InvoiceItem>> invoiceItems(
  InvoiceItemsRef ref,
  String invoiceLocalId,
) {
  return ref.watch(billingRepositoryProvider).watchItems(invoiceLocalId);
}

/// Reactive payments for an invoice.
@riverpod
Stream<List<Payment>> invoicePayments(
  InvoicePaymentsRef ref,
  String invoiceLocalId,
) {
  return ref.watch(billingRepositoryProvider).watchPayments(invoiceLocalId);
}

// ── Mutation providers ────────────────────────────────────────────────────

@riverpod
class CreateInvoiceNotifier extends _$CreateInvoiceNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(CreateInvoiceRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).createInvoice(req),
    );
  }
}

@riverpod
class RecordPaymentNotifier extends _$RecordPaymentNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(RecordPaymentRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).recordPayment(req),
    );
  }
}

@riverpod
class UpdateInvoiceStatusNotifier extends _$UpdateInvoiceStatusNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId, String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).updateStatus(localId, status),
    );
  }
}

@riverpod
class DeleteInvoiceNotifier extends _$DeleteInvoiceNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).deleteInvoice(localId),
    );
  }
}

// ── §9.2 Online-only actions ──────────────────────────────────────────────

@riverpod
class DownloadInvoicePdfNotifier extends _$DownloadInvoicePdfNotifier {
  @override
  FutureOr<File?> build() => null;

  Future<void> execute(String serverId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).downloadPdf(serverId),
    );
  }
}

/// Fetches the income report for a date range (online-only).
@riverpod
Future<IncomeReport> incomeReport(
  IncomeReportRef ref, {
  required String fromDate,
  required String toDate,
}) {
  return ref.watch(billingRepositoryProvider).getIncomeReport(
        fromDate: fromDate,
        toDate: toDate,
      );
}
