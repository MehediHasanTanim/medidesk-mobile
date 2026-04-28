import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/infrastructure_providers.dart';
import '../../../../shared/providers/sync_status_provider.dart';
import '../../data/models/test_order_models.dart';
import '../../data/repositories/test_order_repository.dart';

part 'test_order_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

final testOrderRepositoryProvider = Provider<TestOrderRepository>((ref) {
  return TestOrderRepository(
    db: ref.watch(appDatabaseProvider),
    syncService: ref.watch(syncServiceProvider),
    dio: ref.watch(dioProvider),
  );
});

// ── Read providers ────────────────────────────────────────────────────────

/// Reactive stream of test orders for a consultation — rebuilds when Drift emits.
@riverpod
Stream<List<TestOrder>> testOrdersByConsultation(
  TestOrdersByConsultationRef ref,
  String consultationLocalId,
) {
  return ref
      .watch(testOrderRepositoryProvider)
      .watchByConsultation(consultationLocalId);
}

/// Reactive stream of test orders for a patient.
@riverpod
Stream<List<TestOrder>> testOrdersByPatient(
  TestOrdersByPatientRef ref,
  String patientLocalId,
) {
  return ref
      .watch(testOrderRepositoryProvider)
      .watchByPatient(patientLocalId);
}

/// Single-shot fetch by local ID.
@riverpod
Future<TestOrder?> testOrderDetail(
  TestOrderDetailRef ref,
  String localId,
) {
  return ref.watch(testOrderRepositoryProvider).getById(localId);
}

// ── §10.2 Online-only providers ───────────────────────────────────────────

/// GET /test-orders/mine/ — requires connectivity.
@riverpod
Future<List<TestOrderSummary>> myTestOrders(MyTestOrdersRef ref) {
  return ref.watch(testOrderRepositoryProvider).fetchMyTestOrders();
}

/// GET /test-orders/pending/?patient_id= — requires connectivity.
@riverpod
Future<List<TestOrderSummary>> pendingTestOrders(
  PendingTestOrdersRef ref, {
  String? patientId,
}) {
  return ref
      .watch(testOrderRepositoryProvider)
      .fetchPendingTestOrders(patientId: patientId);
}

// ── Mutation providers ────────────────────────────────────────────────────

/// §10.3 — Bulk creates all test orders for a consultation in one sync op.
@riverpod
class BulkCreateTestOrdersNotifier extends _$BulkCreateTestOrdersNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(BulkCreateTestOrderRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(testOrderRepositoryProvider)
          .createBulkTestOrders(req),
    );
  }
}

@riverpod
class UpdateTestOrderNotifier extends _$UpdateTestOrderNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(UpdateTestOrderRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(testOrderRepositoryProvider)
          .updateTestOrder(req),
    );
  }
}

@riverpod
class DeleteTestOrderNotifier extends _$DeleteTestOrderNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(testOrderRepositoryProvider)
          .deleteTestOrder(localId),
    );
  }
}
