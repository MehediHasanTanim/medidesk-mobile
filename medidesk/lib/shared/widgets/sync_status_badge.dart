import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Per-record badge showing sync state.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.syncStatus});

  final String syncStatus;

  @override
  Widget build(BuildContext context) {
    return switch (syncStatus) {
      'pending' => const Tooltip(
          message: 'Pending sync',
          child: Icon(
            Icons.cloud_upload_outlined,
            size: 16,
            color: AppColors.syncPending,
          ),
        ),
      'processing' => const Tooltip(
          message: 'Syncing…',
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.syncProcessing,
            ),
          ),
        ),
      'failed' => const Tooltip(
          message: 'Sync failed — will retry',
          child: Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: AppColors.syncFailed,
          ),
        ),
      _ => const SizedBox.shrink(), // synced — no badge
    };
  }
}
