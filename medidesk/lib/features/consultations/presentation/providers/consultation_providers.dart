import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/infrastructure_providers.dart';
import '../../../../shared/providers/sync_status_provider.dart';
import '../../data/models/consultation_models.dart';
import '../../data/repositories/consultation_repository.dart';

part 'consultation_providers.g.dart';

final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  return ConsultationRepository(
    db: ref.watch(appDatabaseProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

@riverpod
Stream<List<Consultation>> consultationsByPatient(
  ConsultationsByPatientRef ref,
  String patientLocalId,
) {
  return ref
      .watch(consultationRepositoryProvider)
      .watchByPatient(patientLocalId);
}

@riverpod
Stream<Consultation?> consultationDetail(
  ConsultationDetailRef ref,
  String localId,
) {
  return ref.watch(consultationRepositoryProvider).watchById(localId);
}

@riverpod
Future<Consultation?> consultationById(
  ConsultationByIdRef ref,
  String localId,
) {
  return ref.watch(consultationRepositoryProvider).getById(localId);
}

@riverpod
class StartConsultationNotifier extends _$StartConsultationNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(StartConsultationRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(consultationRepositoryProvider)
          .startConsultation(req),
    );
  }
}

@riverpod
class UpdateDraftNotifier extends _$UpdateDraftNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(UpdateConsultationRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(consultationRepositoryProvider).updateDraft(req),
    );
  }
}

@riverpod
class RecordVitalsNotifier extends _$RecordVitalsNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(UpdateVitalsRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(consultationRepositoryProvider).recordVitals(req),
    );
  }
}

@riverpod
class CompleteConsultationNotifier extends _$CompleteConsultationNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(CompleteConsultationRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(consultationRepositoryProvider)
          .completeConsultation(req, ref.read(dioProvider)),
    );
  }
}

@riverpod
class DeleteConsultationNotifier extends _$DeleteConsultationNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(consultationRepositoryProvider)
          .deleteConsultation(localId),
    );
  }
}
