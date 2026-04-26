import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/sync_status_provider.dart';
import '../../../../shared/providers/infrastructure_providers.dart';
import '../../data/models/patient_model.dart';
import '../../data/repositories/patient_repository.dart';

part 'patient_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(
    db: ref.watch(appDatabaseProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

// ── Search state ──────────────────────────────────────────────────────────

final patientSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Read providers ────────────────────────────────────────────────────────

/// Reactive list — rebuilds whenever Drift emits a new snapshot.
@riverpod
Stream<List<Patient>> patientList(
  PatientListRef ref, {
  String? searchQuery,
}) {
  return ref
      .watch(patientRepositoryProvider)
      .watchAll(searchQuery: searchQuery);
}

/// Single-shot detail fetch; use [patientDetailStreamProvider] for live updates.
@riverpod
Future<Patient?> patientDetail(
  PatientDetailRef ref,
  String localId,
) {
  return ref.watch(patientRepositoryProvider).getById(localId);
}

/// Live stream of a single patient (used in edit form to detect external changes).
@riverpod
Stream<Patient?> patientDetailStream(
  PatientDetailStreamRef ref,
  String localId,
) {
  return ref
      .watch(patientRepositoryProvider)
      .watchAll()
      .map((list) => list.where((p) => p.id == localId).firstOrNull);
}

/// Live notes list for a patient.
@riverpod
Stream<List<PatientNote>> patientNotes(
  PatientNotesRef ref,
  String patientLocalId,
) {
  return ref.watch(patientRepositoryProvider).watchNotes(patientLocalId);
}

// ── Mutation providers ────────────────────────────────────────────────────

@riverpod
class CreatePatientNotifier extends _$CreatePatientNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(CreatePatientRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(patientRepositoryProvider).createPatient(req),
    );
  }
}

@riverpod
class UpdatePatientNotifier extends _$UpdatePatientNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(UpdatePatientRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(patientRepositoryProvider).updatePatient(req),
    );
  }
}

@riverpod
class DeletePatientNotifier extends _$DeletePatientNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(patientRepositoryProvider).deletePatient(localId),
    );
  }
}

@riverpod
class AddPatientNoteNotifier extends _$AddPatientNoteNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute({
    required String patientLocalId,
    required String content,
    String? userId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .addNote(patientLocalId, content, userId),
    );
  }
}
