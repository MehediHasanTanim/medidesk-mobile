import 'package:dio/dio.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/medicine_models.dart';

// ── Interface ──────────────────────────────────────────────────────────────

abstract class IMedicineRepository {
  /// §8.3 — Local-first search with server fallback.
  ///
  /// 1. Queries local Drift tables (always works offline).
  /// 2. If local result is empty **and** online: falls back to
  ///    `GET /medicines/search/?q=&limit=`.
  Future<List<MedicineSearchResult>> search(String query, {int limit});

  /// Reactive brand search stream — used by the prescription form to keep the
  /// dropdown live as the user types.
  Stream<List<BrandMedicine>> watchBrandSearch(String query, {String? form});

  /// Reactive generic search stream.
  Stream<List<GenericMedicine>> watchGenericSearch(String query);

  /// Fetch a single brand medicine from the local cache.
  Future<BrandMedicine?> getBrandById(String id);

  /// Fetch a single generic medicine from the local cache.
  Future<GenericMedicine?> getGenericById(String id);
}

// ── Implementation ─────────────────────────────────────────────────────────

class MedicineRepository implements IMedicineRepository {
  MedicineRepository({
    required AppDatabase db,
    required Dio dio,
    required ConnectivityService connectivity,
  })  : _db = db,
        _dio = dio,
        _connectivity = connectivity;

  final AppDatabase _db;
  final Dio _dio;
  final ConnectivityService _connectivity;

  // ── §8.3 Search ──────────────────────────────────────────────────────────

  @override
  Future<List<MedicineSearchResult>> search(
    String query, {
    int limit = 20,
  }) async {
    // 1. Search local Drift first — works offline
    final brandRows =
        await _db.medicineDao.searchBrandOnce(query, limit: limit);
    if (brandRows.isNotEmpty) {
      return brandRows.map(_brandRowToResult).toList();
    }

    final genericRows =
        await _db.medicineDao.searchGenericOnce(query, limit: limit);
    if (genericRows.isNotEmpty) {
      return genericRows.map(_genericRowToResult).toList();
    }

    // 2. Fallback to server search when local is empty and online
    if (await _connectivity.isOnline) {
      return _searchOnServer(query, limit: limit);
    }

    return const [];
  }

  Future<List<MedicineSearchResult>> _searchOnServer(
    String query, {
    int limit = 20,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.medicineSearch,
      queryParameters: {'q': query, 'limit': limit},
    );
    final results =
        (resp.data!['results'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return results.map(_serverResultToModel).toList();
  }

  // ── Reactive streams ─────────────────────────────────────────────────────

  @override
  Stream<List<BrandMedicine>> watchBrandSearch(String query, {String? form}) =>
      _db.medicineDao
          .searchBrand(query, form: form)
          .map((rows) => rows.map(_brandRowToDomain).toList());

  @override
  Stream<List<GenericMedicine>> watchGenericSearch(String query) =>
      _db.medicineDao
          .searchGeneric(query)
          .map((rows) => rows.map(_genericRowToDomain).toList());

  // ── Point reads ──────────────────────────────────────────────────────────

  @override
  Future<BrandMedicine?> getBrandById(String id) async {
    final row = await _db.medicineDao.getBrandById(id);
    return row == null ? null : _brandRowToDomain(row);
  }

  @override
  Future<GenericMedicine?> getGenericById(String id) async {
    final row = await _db.medicineDao.getGenericById(id);
    return row == null ? null : _genericRowToDomain(row);
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────

  BrandMedicine _brandRowToDomain(BrandMedicineRow r) => BrandMedicine(
        id: r.id,
        genericId: r.genericId,
        brandName: r.brandName,
        manufacturer: r.manufacturer,
        strength: r.strength,
        form: r.form,
        mrp: r.mrp,
        isActive: r.isActive == 1,
      );

  GenericMedicine _genericRowToDomain(GenericMedicineRow r) => GenericMedicine(
        id: r.id,
        genericName: r.genericName,
        drugClass: r.drugClass,
        therapeuticClass: r.therapeuticClass,
        indications: r.indications,
        contraindications: r.contraindications,
        sideEffects: r.sideEffects,
      );

  MedicineSearchResult _brandRowToResult(BrandMedicineRow r) =>
      MedicineSearchResult(
        id: r.id,
        displayName: '${r.brandName} ${r.strength} (${r.form})',
        isBrand: true,
        genericId: r.genericId,
        manufacturer: r.manufacturer,
        strength: r.strength,
        form: r.form,
        mrp: r.mrp,
      );

  MedicineSearchResult _genericRowToResult(GenericMedicineRow r) =>
      MedicineSearchResult(
        id: r.id,
        displayName: r.genericName,
        isBrand: false,
        genericId: r.id,
        genericName: r.genericName,
      );

  MedicineSearchResult _serverResultToModel(Map<String, dynamic> m) {
    // Server returns a unified result; prefer brand fields when present.
    final brandName = m['brand_name'] as String?;
    final genericName = m['generic_name'] as String? ?? '';
    final strength = m['strength'] as String?;
    final form = m['form'] as String?;
    final isBrand = brandName != null;

    final displayName = isBrand
        ? '$brandName${strength != null ? ' $strength' : ''}${form != null ? ' ($form)' : ''}'
        : genericName;

    return MedicineSearchResult(
      id: m['id'] as String,
      displayName: displayName,
      isBrand: isBrand,
      genericId: m['generic_id'] as String? ?? (isBrand ? null : m['id'] as String?),
      genericName: genericName.isEmpty ? null : genericName,
      manufacturer: m['manufacturer'] as String?,
      strength: strength,
      form: form,
      mrp: (m['mrp'] as num?)?.toDouble(),
    );
  }
}
