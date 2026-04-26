import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_status_provider.dart';
import '../../core/theme/app_colors.dart';

class SyncProgressIndicator extends ConsumerWidget {
  const SyncProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingSyncCountProvider);
    return count.when(
      data: (n) => n > 0
          ? Tooltip(
              message: '$n item${n == 1 ? '' : 's'} pending sync',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.syncPending,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$n',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.syncPending,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
