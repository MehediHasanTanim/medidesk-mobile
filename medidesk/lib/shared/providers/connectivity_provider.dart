import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';

/// Injectable — overridden in ProviderScope with the singleton created in main().
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => throw UnimplementedError(
    'connectivityServiceProvider must be overridden in ProviderScope',
  ),
);

/// Reactive online/offline flag — all widgets watch this for the offline banner.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});
