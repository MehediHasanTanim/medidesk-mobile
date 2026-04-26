import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_endpoints.dart';
import '../storage/preferences_service.dart';

/// Syncs read-only lookup tables on app launch.
/// Medicines are refreshed only when the local cache is older than [_medicineRefreshInterval].
class LookupSyncHandler {
  const LookupSyncHandler({
    required Dio dio,
    required AppDatabase db,
    required PreferencesService prefs,
  })  : _dio = dio,
        _db = db,
        _prefs = prefs;

  final Dio _dio;
  final AppDatabase _db;
  final PreferencesService _prefs;

  static const Duration _medicineRefreshInterval = Duration(days: 7);

  Future<void> syncAll() async {
    await Future.wait([
      _syncChambers(),
      _syncUsers(),
      _syncSpecialities(),
      _syncDoctorProfiles(),
    ]);
    await _syncMedicinesIfStale();
    await _prefs.setLookupLastSync(DateTime.now().millisecondsSinceEpoch);
  }

  // ── Individual syncs ─────────────────────────────────────────────────

  Future<void> _syncChambers() async {
    final resp = await _dio.get<List<dynamic>>(ApiEndpoints.chambers);
    final rows = (resp.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(_chamberToCompanion)
        .toList();
    await _db.chamberDao.upsertAll(rows);
  }

  Future<void> _syncUsers() async {
    final resp = await _dio.get<List<dynamic>>(ApiEndpoints.users);
    final rows = (resp.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(_userToCompanion)
        .toList();
    await _db.userDao.upsertAll(rows);
  }

  Future<void> _syncSpecialities() async {
    final resp = await _dio.get<List<dynamic>>(ApiEndpoints.specialities);
    final rows = (resp.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(_specialityToCompanion)
        .toList();
    await _db.specialityDao.upsertAll(rows);
  }

  Future<void> _syncDoctorProfiles() async {
    final resp = await _dio.get<List<dynamic>>(ApiEndpoints.doctorProfiles);
    final rows = (resp.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(_doctorProfileToCompanion)
        .toList();
    await _db.doctorProfileDao.upsertAll(rows);
  }

  Future<void> _syncMedicinesIfStale() async {
    final lastMs = _prefs.getMedicineLastSync();
    if (lastMs != null) {
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastMs));
      if (age < _medicineRefreshInterval) return;
    }
    await Future.wait([_syncGenericMedicines(), _syncBrandMedicines()]);
    await _prefs.setMedicineLastSync(DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _syncGenericMedicines() async {
    int page = 1;
    while (true) {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.genericMedicines,
        queryParameters: {'page': page, 'limit': 500},
      );
      final data = resp.data!;
      final results = (data['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_genericMedicineToCompanion)
          .toList();
      await _db.medicineDao.upsertAllGeneric(results);
      if (data['next'] == null) break;
      page++;
    }
  }

  Future<void> _syncBrandMedicines() async {
    int page = 1;
    while (true) {
      final resp = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.brandMedicines,
        queryParameters: {'page': page, 'limit': 500},
      );
      final data = resp.data!;
      final results = (data['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_brandMedicineToCompanion)
          .toList();
      await _db.medicineDao.upsertAllBrand(results);
      if (data['next'] == null) break;
      page++;
    }
  }

  // ── Mapping helpers ───────────────────────────────────────────────────

  ChambersCompanion _chamberToCompanion(Map<String, dynamic> m) =>
      ChambersCompanion.insert(
        id: m['id'] as String,
        name: m['name'] as String,
        address: m['address'] as String,
        phone: m['phone'] as String,
        latitude: Value(m['latitude'] as double?),
        longitude: Value(m['longitude'] as double?),
        isActive: Value(((m['is_active'] as bool?) ?? true) ? 1 : 0),
        createdAt: m['created_at'] as String,
      );

  UsersCompanion _userToCompanion(Map<String, dynamic> m) =>
      UsersCompanion.insert(
        id: m['id'] as String,
        fullName: m['full_name'] as String,
        role: m['role'] as String,
        supervisorId: Value(m['supervisor_id'] as String?),
        username: m['username'] as String,
        email: Value(m['email'] as String?),
        isActive: Value(((m['is_active'] as bool?) ?? true) ? 1 : 0),
        dateJoined: m['date_joined'] as String,
      );

  SpecialitiesCompanion _specialityToCompanion(Map<String, dynamic> m) =>
      SpecialitiesCompanion.insert(
        id: m['id'] as String,
        name: m['name'] as String,
        description: Value(m['description'] as String? ?? ''),
        isActive: Value(((m['is_active'] as bool?) ?? true) ? 1 : 0),
        createdAt: m['created_at'] as String,
      );

  DoctorProfilesCompanion _doctorProfileToCompanion(
          Map<String, dynamic> m) =>
      DoctorProfilesCompanion.insert(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        specialityId: m['speciality_id'] as String,
        qualifications: m['qualifications'] as String,
        bio: Value(m['bio'] as String? ?? ''),
        consultationFee: Value((m['consultation_fee'] as num?)?.toDouble()),
        experienceYears: Value(m['experience_years'] as int?),
        isAvailable: Value(((m['is_available'] as bool?) ?? true) ? 1 : 0),
        visitDays: Value(m['visit_days']?.toString() ?? '[]'),
        visitTimeStart: Value(m['visit_time_start'] as String?),
        visitTimeEnd: Value(m['visit_time_end'] as String?),
      );

  GenericMedicinesCompanion _genericMedicineToCompanion(
          Map<String, dynamic> m) =>
      GenericMedicinesCompanion.insert(
        id: m['id'] as String,
        genericName: m['generic_name'] as String,
        drugClass: m['drug_class'] as String,
        therapeuticClass: Value(m['therapeutic_class'] as String? ?? ''),
        indications: Value(m['indications'] as String? ?? ''),
        contraindications: Value(m['contraindications']?.toString() ?? '[]'),
        sideEffects: Value(m['side_effects'] as String? ?? ''),
      );

  BrandMedicinesCompanion _brandMedicineToCompanion(
          Map<String, dynamic> m) =>
      BrandMedicinesCompanion.insert(
        id: m['id'] as String,
        genericId: m['generic_id'] as String,
        brandName: m['brand_name'] as String,
        manufacturer: m['manufacturer'] as String,
        strength: m['strength'] as String,
        form: m['form'] as String,
        mrp: Value((m['mrp'] as num?)?.toDouble()),
        isActive: Value(((m['is_active'] as bool?) ?? true) ? 1 : 0),
      );
}
