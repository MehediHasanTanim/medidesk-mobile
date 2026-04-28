import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/infrastructure_providers.dart';
import '../../../../shared/providers/sync_status_provider.dart';
import '../../data/models/prescription_models.dart';
import '../../data/repositories/prescription_repository.dart';

part 'prescription_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

final prescriptionRepositoryProvider =
    Provider<PrescriptionRepository>((ref) {
  return PrescriptionRepository(
    db: ref.watch(appDatabaseProvider),
    syncService: ref.watch(syncServiceProvider),
    dio: ref.watch(dioProvider),
  );
});

// ── Read providers ────────────────────────────────────────────────────────

/// Reactive prescription for a consultation — rebuilds when Drift emits.
@riverpod
Stream<Prescription?> prescriptionByConsultation(
  PrescriptionByConsultationRef ref,
  String consultationLocalId,
) {
  return ref
      .watch(prescriptionRepositoryProvider)
      .watchByConsultation(consultationLocalId);
}

/// All prescriptions for a patient — ordered newest first.
@riverpod
Stream<List<Prescription>> prescriptionsByPatient(
  PrescriptionsByPatientRef ref,
  String patientLocalId,
) {
  return ref
      .watch(prescriptionRepositoryProvider)
      .watchByPatient(patientLocalId);
}

/// Live stream of items for a prescription.
@riverpod
Stream<List<PrescriptionItem>> prescriptionItems(
  PrescriptionItemsRef ref,
  String prescriptionLocalId,
) {
  return ref
      .watch(prescriptionRepositoryProvider)
      .watchItems(prescriptionLocalId);
}

/// Single-shot detail fetch.
@riverpod
Future<Prescription?> prescriptionDetail(
  PrescriptionDetailRef ref,
  String localId,
) {
  return ref.watch(prescriptionRepositoryProvider).getById(localId);
}

// ── Mutation providers ────────────────────────────────────────────────────

@riverpod
class CreatePrescriptionNotifier extends _$CreatePrescriptionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(CreatePrescriptionRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(prescriptionRepositoryProvider)
          .createPrescription(req),
    );
  }
}

@riverpod
class UpdatePrescriptionItemsNotifier
    extends _$UpdatePrescriptionItemsNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(UpdatePrescriptionRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(prescriptionRepositoryProvider)
          .updateItems(req),
    );
  }
}

/// §2.5 — Approve is online-only.
@riverpod
class ApprovePrescriptionNotifier extends _$ApprovePrescriptionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(prescriptionRepositoryProvider)
          .approvePrescription(localId),
    );
  }
}

/// §2.5 — Send is online-only.
@riverpod
class SendPrescriptionNotifier extends _$SendPrescriptionNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(prescriptionRepositoryProvider)
          .sendPrescription(localId),
    );
  }
}

/// §7.5 — Download PDF is online-only (binary streaming).
@riverpod
class DownloadPrescriptionPdfNotifier
    extends _$DownloadPrescriptionPdfNotifier {
  @override
  FutureOr<File?> build() => null;

  Future<void> execute(String serverId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(prescriptionRepositoryProvider)
          .downloadPdf(serverId),
    );
  }
}
