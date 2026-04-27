import 'dart:async';
import '../connectivity/connectivity_service.dart';
import 'pull_sync_handler.dart';
import 'sync_queue_processor.dart';
import 'lookup_sync_handler.dart';

class SyncService {
  SyncService({
    required PullSyncHandler pullHandler,
    required SyncQueueProcessor queueProcessor,
    required LookupSyncHandler lookupHandler,
    required ConnectivityService connectivity,
  })  : _pullHandler = pullHandler,
        _queueProcessor = queueProcessor,
        _lookupHandler = lookupHandler,
        _connectivity = connectivity;

  final PullSyncHandler _pullHandler;
  final SyncQueueProcessor _queueProcessor;
  final LookupSyncHandler _lookupHandler;
  final ConnectivityService _connectivity;

  StreamSubscription<bool>? _connectivitySub;
  bool _isSyncing = false;

  /// Called once on app launch.
  Future<void> initialize() async {
    final online = await _connectivity.isOnline;
    if (online) {
      unawaited(_fullSync());
    }

    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline && !_isSyncing) {
        unawaited(pushSync());
      }
    });
  }

  Future<void> _fullSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _lookupHandler.syncAll();
      await _pullHandler.pullSync();
      await _queueProcessor.pushSync();
    } catch (_) {
      // Sync errors are non-fatal; queue will retry
    } finally {
      _isSyncing = false;
    }
  }

  /// Called from repositories after local write, and from WorkManager.
  Future<void> pushSync() async {
    final online = await _connectivity.isOnline;
    if (!online) return;
    try {
      await _queueProcessor.pushSync();
    } catch (_) {
      // Non-fatal
    }
  }

  /// Triggers a full sync (lookup + pull + push) without touching the
  /// connectivity subscription.  Called after login to populate Drift tables.
  Future<void> triggerFullSync() async {
    final online = await _connectivity.isOnline;
    if (online && !_isSyncing) {
      unawaited(_fullSync());
    }
  }

  /// Full pull + push — called from WorkManager background task.
  Future<void> backgroundSync() async {
    final online = await _connectivity.isOnline;
    if (!online) return;
    try {
      await _pullHandler.pullSync();
      await _queueProcessor.pushSync();
    } catch (_) {
      // Non-fatal in background
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
