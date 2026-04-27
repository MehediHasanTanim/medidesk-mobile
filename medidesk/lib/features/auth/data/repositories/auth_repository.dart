import 'dart:async' show unawaited;

import 'package:dio/dio.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../models/auth_models.dart';

// ── Interface ─────────────────────────────────────────────────────────────

abstract class IAuthRepository {
  /// POST /auth/login/ — stores tokens, persists user info, triggers sync.
  Future<LoginUser> login(String username, String password);

  /// POST /auth/logout/ — blacklists refresh token, wipes all local state.
  Future<void> logout();

  /// GET /auth/me/
  Future<UserProfile> getProfile();

  /// PATCH /auth/me/
  Future<UserProfile> updateProfile({String? fullName, String? email});

  /// POST /auth/change-password/
  Future<void> changePassword(ChangePasswordRequest req);
}

// ── Implementation ────────────────────────────────────────────────────────

class AuthRepository implements IAuthRepository {
  AuthRepository({
    required Dio dio,
    required SecureStorageService storage,
    required PreferencesService prefs,
    required SyncService syncService,
    required AppDatabase db,
  })  : _dio = dio,
        _storage = storage,
        _prefs = prefs,
        _syncService = syncService,
        _db = db;

  final Dio _dio;
  final SecureStorageService _storage;
  final PreferencesService _prefs;
  final SyncService _syncService;
  final AppDatabase _db;

  // ── Auth actions ──────────────────────────────────────────────────────

  @override
  Future<LoginUser> login(String username, String password) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );
    final loginResp = LoginResponse.fromJson(resp.data!);

    // Persist tokens
    await _storage.saveTokens(
      accessToken: loginResp.access,
      refreshToken: loginResp.refresh,
    );

    // Persist user identity
    await _storage.saveUser(
      userId: loginResp.user.id,
      role: loginResp.user.role,
    );

    // Persist chamber membership for UI-layer filtering
    await _prefs.setChamberIds(loginResp.user.chamberIds);

    // Trigger full sync non-blocking — populates Drift tables after login
    unawaited(_syncService.triggerFullSync());

    return loginResp.user;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();

    // Best-effort server call — blacklists the refresh token
    if (refreshToken != null) {
      try {
        await _dio.post<void>(
          ApiEndpoints.logout,
          data: {'refresh': refreshToken},
        );
      } catch (_) {
        // Server call failures must not block local cleanup
      }
    }

    // Wipe all local state
    await Future.wait([
      _storage.clearAll(),
      _prefs.clearAll(),
    ]);
    await _db.wipeAll();
  }

  // ── Profile ───────────────────────────────────────────────────────────

  @override
  Future<UserProfile> getProfile() async {
    final resp =
        await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
    return UserProfile.fromJson(resp.data!);
  }

  @override
  Future<UserProfile> updateProfile({
    String? fullName,
    String? email,
  }) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.me,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
      },
    );
    return UserProfile.fromJson(resp.data!);
  }

  @override
  Future<void> changePassword(ChangePasswordRequest req) async {
    await _dio.post<void>(
      ApiEndpoints.changePassword,
      data: req.toJson(),
    );
  }
}
