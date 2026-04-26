import 'package:workmanager/workmanager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/app_database.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import '../storage/preferences_service.dart';
import '../connectivity/connectivity_service.dart';
import '../config/app_config.dart';
import 'pull_sync_handler.dart';
import 'sync_queue_processor.dart';

const _taskName = 'medidesk_background_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskName) return Future.value(false);

    try {
      final db = AppDatabase();
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      const storage = SecureStorageService(const FlutterSecureStorage());
      final connectivity = ConnectivityService(Connectivity());

      final isOnline = await connectivity.isOnline;
      if (!isOnline) return Future.value(true);

      final dio = DioClient.create(
        baseUrl: AppConfig.current.baseUrl,
        storage: storage,
      );

      await PullSyncHandler(dio: dio, db: db, prefs: prefs).pullSync();
      await SyncQueueProcessor(dio: dio, db: db).pushSync();

      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}

Future<void> registerBackgroundSync() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    _taskName,
    _taskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
