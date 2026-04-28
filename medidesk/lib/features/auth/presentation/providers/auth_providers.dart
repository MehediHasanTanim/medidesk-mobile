import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/infrastructure_providers.dart';
import '../../../../shared/providers/sync_status_provider.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

// ── Repository ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(secureStorageServiceProvider),
    prefs: ref.watch(preferencesServiceProvider),
    syncService: ref.watch(syncServiceProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

// ── Auth state ─────────────────────────────────────────────────────────────

/// Mutable flag: updated synchronously on login, logout, and app-startup check.
/// The router watches this to drive /login ↔ /dashboard redirects.
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

// ── Login ──────────────────────────────────────────────────────────────────

@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(username, password);
      // Mark authenticated — router redirect fires automatically
      ref.read(isAuthenticatedProvider.notifier).state = true;
    });
  }
}

// ── Logout ─────────────────────────────────────────────────────────────────

@riverpod
class LogoutNotifier extends _$LogoutNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).logout();
      // Clear auth flag — router redirect fires automatically
      ref.read(isAuthenticatedProvider.notifier).state = false;
    });
  }
}

// ── Current user display name (sync, from SharedPreferences) ───────────────

/// Returns the full name persisted at login time. Falls back to 'Doctor' if
/// not yet set (e.g. first cold-start before any login).
final currentUserNameProvider = Provider<String>((ref) {
  return ref.watch(preferencesServiceProvider).getFullName() ?? 'Doctor';
});

// ── Profile ────────────────────────────────────────────────────────────────

@riverpod
Future<UserProfile> userProfile(UserProfileRef ref) {
  return ref.watch(authRepositoryProvider).getProfile();
}

@riverpod
class UpdateProfileNotifier extends _$UpdateProfileNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute({String? fullName, String? email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(fullName: fullName, email: email);
      ref.invalidate(userProfileProvider);
    });
  }
}

// ── Change password ────────────────────────────────────────────────────────

@riverpod
class ChangePasswordNotifier extends _$ChangePasswordNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(ChangePasswordRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).changePassword(req),
    );
  }
}
