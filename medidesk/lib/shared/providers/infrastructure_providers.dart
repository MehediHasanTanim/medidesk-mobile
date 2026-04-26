/// Central infrastructure providers.
///
/// Every provider here is declared with a placeholder implementation that
/// throws [UnimplementedError] — they MUST be overridden in [ProviderScope]
/// inside `main.dart`. This pattern makes the dependency graph explicit and
/// testable (swap any singleton with a fake in widget tests).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_service.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/secure_storage_service.dart';

final syncServiceProvider = Provider<SyncService>(
  (ref) => throw UnimplementedError('syncServiceProvider must be overridden'),
);

final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) =>
      throw UnimplementedError('preferencesServiceProvider must be overridden'),
);

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => throw UnimplementedError(
      'secureStorageServiceProvider must be overridden'),
);
