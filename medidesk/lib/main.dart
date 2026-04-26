import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/config/app_config.dart';
import 'core/config/router_config.dart';
import 'core/database/app_database.dart';
import 'core/network/dio_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/storage/preferences_service.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/sync/sync_service.dart';
import 'core/sync/pull_sync_handler.dart';
import 'core/sync/sync_queue_processor.dart';
import 'core/sync/lookup_sync_handler.dart';
import 'core/sync/background_sync_task.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/sync_status_provider.dart';
import 'shared/providers/connectivity_provider.dart';
import 'shared/providers/infrastructure_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise all timezone data (needed for Asia/Dhaka display)
  tz.initializeTimeZones();

  // Register WorkManager periodic background-sync task (15 min, online-only)
  await registerBackgroundSync();

  // ── Bootstrap core singletons ────────────────────────────────────────────
  final sharedPrefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  final prefsService = PreferencesService(sharedPrefs);
  const storageService = SecureStorageService(secureStorage);
  final connectivityService = ConnectivityService(Connectivity());
  final db = AppDatabase();

  final dio = DioClient.create(
    baseUrl: AppConfig.current.baseUrl,
    storage: storageService,
  );

  final syncService = SyncService(
    pullHandler: PullSyncHandler(dio: dio, db: db, prefs: prefsService),
    queueProcessor: SyncQueueProcessor(dio: dio, db: db),
    lookupHandler: LookupSyncHandler(dio: dio, db: db, prefs: prefsService),
    connectivity: connectivityService,
  );

  // Non-blocking — pull lookup tables + pending queue on first launch
  unawaited(syncService.initialize());

  runApp(
    ProviderScope(
      overrides: [
        // Core infrastructure — override with real instances
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        connectivityServiceProvider.overrideWithValue(connectivityService),
        syncServiceProvider.overrideWithValue(syncService),
        preferencesServiceProvider.overrideWithValue(prefsService),
        secureStorageServiceProvider.overrideWithValue(storageService),
      ],
      child: const MediDeskApp(),
    ),
  );
}

class MediDeskApp extends ConsumerWidget {
  const MediDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MediDesk',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
