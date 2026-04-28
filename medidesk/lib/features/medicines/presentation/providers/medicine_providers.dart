import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/infrastructure_providers.dart';
import '../../../../shared/providers/sync_status_provider.dart';
import '../../data/models/medicine_models.dart';
import '../../data/repositories/medicine_repository.dart';

part 'medicine_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  return MedicineRepository(
    db: ref.watch(appDatabaseProvider),
    dio: ref.watch(dioProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

// ── §8.3 Autocomplete search ──────────────────────────────────────────────

/// One-shot search used by the prescription form autocomplete.
///
/// Local-first: queries Drift synchronously, falls back to
/// `GET /medicines/search/` only when local is empty and online.
/// Parametrised by [query] and [limit] — Riverpod caches by both.
@riverpod
Future<List<MedicineSearchResult>> medicineSearch(
  MedicineSearchRef ref,
  String query, {
  int limit = 20,
}) {
  if (query.trim().isEmpty) return Future.value(const []);
  return ref
      .watch(medicineRepositoryProvider)
      .search(query.trim(), limit: limit);
}

// ── Reactive brand / generic streams ─────────────────────────────────────

/// Live brand search stream — rebuilds as the user types in an autocomplete
/// field.  Pass [form] (e.g. `'tablet'`) to filter by dosage form.
@riverpod
Stream<List<BrandMedicine>> brandMedicineSearch(
  BrandMedicineSearchRef ref,
  String query, {
  String? form,
}) {
  if (query.trim().isEmpty) return Stream.value(const []);
  return ref
      .watch(medicineRepositoryProvider)
      .watchBrandSearch(query.trim(), form: form);
}

/// Live generic search stream.
@riverpod
Stream<List<GenericMedicine>> genericMedicineSearch(
  GenericMedicineSearchRef ref,
  String query,
) {
  if (query.trim().isEmpty) return Stream.value(const []);
  return ref
      .watch(medicineRepositoryProvider)
      .watchGenericSearch(query.trim());
}

// ── Point-read providers ─────────────────────────────────────────────────

@riverpod
Future<BrandMedicine?> brandMedicineDetail(
  BrandMedicineDetailRef ref,
  String id,
) {
  return ref.watch(medicineRepositoryProvider).getBrandById(id);
}

@riverpod
Future<GenericMedicine?> genericMedicineDetail(
  GenericMedicineDetailRef ref,
  String id,
) {
  return ref.watch(medicineRepositoryProvider).getGenericById(id);
}
