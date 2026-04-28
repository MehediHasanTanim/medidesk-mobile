import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointment_providers.dart';

class QueueManagementScreen extends ConsumerStatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  ConsumerState<QueueManagementScreen> createState() =>
      _QueueManagementScreenState();
}

class _QueueManagementScreenState extends ConsumerState<QueueManagementScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Advance a [QueueItem] to its next status.
  /// Looks up the local record by server ID so the write goes through the
  /// offline-first repository (write local → enqueue → pushSync).
  Future<void> _advanceQueueItem(QueueItem item) async {
    final next = item.status == 'in_queue' ? 'in_progress' : 'completed';
    final local = await ref
        .read(appointmentRepositoryProvider)
        .getByServerId(item.id);
    if (local == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment not found locally — try syncing first'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    await ref
        .read(updateAppointmentStatusNotifierProvider.notifier)
        .execute(local.id, next);
  }

  /// Advance a local [Appointment] (used in offline fallback mode).
  Future<void> _advanceAppointment(Appointment appt) async {
    final next = appt.status == 'in_queue' ? 'in_progress' : 'completed';
    await ref
        .read(updateAppointmentStatusNotifierProvider.notifier)
        .execute(appt.id, next);
  }

  @override
  Widget build(BuildContext context) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Dark green header ──────────────────────────────────────────
          _buildHeader(isOnline),

          // ── Offline notice band ────────────────────────────────────────
          if (!isOnline) _OfflineBanner(),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: isOnline
                ? _OnlineQueueBody(pulse: _pulse, onAdvance: _advanceQueueItem)
                : _OfflineQueueBody(
                    pulse: _pulse, onAdvance: _advanceAppointment),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isOnline) {
    // Header count comes from the active data source
    final countWidget = isOnline
        ? ref.watch(queueStreamProvider).when(
              loading: () => const _QueueHeader(count: 0, isOnline: true),
              error: (_, __) => const _QueueHeader(count: 0, isOnline: true),
              data: (q) => _QueueHeader(count: q.length, isOnline: true),
            )
        : ref
            .watch(appointmentQueueProvider(DateTime.now()))
            .when(
              loading: () => const _QueueHeader(count: 0, isOnline: false),
              error: (_, __) => const _QueueHeader(count: 0, isOnline: false),
              data: (q) => _QueueHeader(count: q.length, isOnline: false),
            );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E3A2C), Color(0xFF1A6E54)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/appointments/new'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Walk-in',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              countWidget,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Online queue body ─────────────────────────────────────────────────────

class _OnlineQueueBody extends ConsumerWidget {
  const _OnlineQueueBody({
    required this.pulse,
    required this.onAdvance,
  });

  final AnimationController pulse;
  final Future<void> Function(QueueItem) onAdvance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueStreamProvider);

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (queue) => _QueueListView(
        inProgress: queue.where((i) => i.status == 'in_progress').toList(),
        waiting: queue.where((i) => i.status == 'in_queue').toList(),
        pulse: pulse,
        onAdvanceInProgress: (item) => onAdvance(item),
        onCallNext: (item) => onAdvance(item),
      ),
    );
  }
}

// ── Offline fallback body ─────────────────────────────────────────────────

class _OfflineQueueBody extends ConsumerWidget {
  const _OfflineQueueBody({
    required this.pulse,
    required this.onAdvance,
  });

  final AnimationController pulse;
  final Future<void> Function(Appointment) onAdvance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(appointmentQueueProvider(DateTime.now()));

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (queue) {
        final inProgress =
            queue.where((a) => a.status == 'in_progress').toList();
        final waiting =
            queue.where((a) => a.status == 'in_queue').toList();

        // Convert Appointment → _QueueEntry for the shared list view
        return _QueueListView(
          inProgress: inProgress
              .map((a) => QueueItem(
                    id: a.serverId ?? a.id,
                    patientId: a.patientId,
                    status: a.status,
                    tokenNumber: a.tokenNumber,
                    scheduledAt: a.scheduledAt,
                    appointmentType: a.appointmentType,
                    chamberId: a.chamberId,
                    notes: a.notes,
                  ))
              .toList(),
          waiting: waiting
              .map((a) => QueueItem(
                    id: a.serverId ?? a.id,
                    patientId: a.patientId,
                    status: a.status,
                    tokenNumber: a.tokenNumber,
                    scheduledAt: a.scheduledAt,
                    appointmentType: a.appointmentType,
                    chamberId: a.chamberId,
                    notes: a.notes,
                  ))
              .toList(),
          pulse: pulse,
          // In offline mode actions map back to the local Appointment
          onAdvanceInProgress: (item) {
            final appt = inProgress.firstWhere(
              (a) => (a.serverId ?? a.id) == item.id,
              orElse: () => inProgress.first,
            );
            return onAdvance(appt);
          },
          onCallNext: (item) {
            final appt = waiting.firstWhere(
              (a) => (a.serverId ?? a.id) == item.id,
              orElse: () => waiting.first,
            );
            return onAdvance(appt);
          },
        );
      },
    );
  }
}

// ── Shared queue list view ────────────────────────────────────────────────

class _QueueListView extends StatelessWidget {
  const _QueueListView({
    required this.inProgress,
    required this.waiting,
    required this.pulse,
    required this.onAdvanceInProgress,
    required this.onCallNext,
  });

  final List<QueueItem> inProgress;
  final List<QueueItem> waiting;
  final AnimationController pulse;
  final Future<void> Function(QueueItem) onAdvanceInProgress;
  final Future<void> Function(QueueItem) onCallNext;

  @override
  Widget build(BuildContext context) {
    final nowServing = inProgress.isNotEmpty ? inProgress.first : null;

    if (nowServing == null && waiting.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_outlined, size: 48, color: AppColors.muted),
            SizedBox(height: 12),
            Text('Queue is empty',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted)),
            SizedBox(height: 4),
            Text('Check in a patient to begin',
                style: TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 80),
      children: [
        // Now serving card
        if (nowServing != null)
          _NowServingCard(
            item: nowServing,
            pulse: pulse,
            onAdvance: () => onAdvanceInProgress(nowServing),
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.muted, size: 24),
                SizedBox(width: 12),
                Text('No one being seen right now',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

        if (waiting.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('UP NEXT',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          ...waiting.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _QueueRow(
                    item: e.value,
                    position: e.key,
                    onCallNext: e.key == 0 ? () => onCallNext(e.value) : null,
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.count, required this.isOnline});
  final int count;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF22C97C)
                        : AppColors.muted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'LIVE QUEUE' : 'LOCAL QUEUE',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xCCFFFFFF),
                      letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count waiting',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Offline banner ────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF3A847).withValues(alpha: 0.15),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 14, color: Color(0xFFF3A847)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline — showing local queue. Live updates paused.',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF3A847)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Now serving card ──────────────────────────────────────────────────────

class _NowServingCard extends StatelessWidget {
  const _NowServingCard({
    required this.item,
    required this.pulse,
    required this.onAdvance,
  });
  final QueueItem item;
  final AnimationController pulse;
  final VoidCallback onAdvance;

  String get _label {
    if (item.patientName != null && item.patientName!.isNotEmpty) {
      return item.patientName!;
    }
    return 'Patient ${item.patientId.substring(0, 6).toUpperCase()}';
  }

  String get _token =>
      item.tokenNumber != null ? '#${item.tokenNumber}' : '—';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing token badge
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) {
              final v = pulse.value;
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft,
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(alpha: 0.5 * (1 - v)),
                      blurRadius: 16 * v,
                      spreadRadius: 8 * v,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: Center(
                      child: Text(_token,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Colors.white)),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NOW SERVING',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(_label, style: Theme.of(context).textTheme.titleMedium),
                const Text('In room',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdvance,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text('Done',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Queue row ─────────────────────────────────────────────────────────────

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.item,
    required this.position,
    this.onCallNext,
  });
  final QueueItem item;
  final int position;
  final VoidCallback? onCallNext;

  bool get _isNext => position == 0;

  String get _label {
    if (item.patientName != null && item.patientName!.isNotEmpty) {
      return item.patientName!;
    }
    return 'Patient ${item.patientId.substring(0, 6).toUpperCase()}';
  }

  String get _token =>
      item.tokenNumber != null ? '#${item.tokenNumber}' : '—';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isNext ? AppColors.primarySoft : AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_token,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: _isNext
                          ? AppColors.primaryDark
                          : AppColors.ink2)),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              item.patientId.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label, style: tt.titleSmall?.copyWith(fontSize: 13)),
                Text('Waiting · position ${position + 1}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted)),
              ],
            ),
          ),
          if (_isNext && onCallNext != null)
            GestureDetector(
              onTap: onCallNext,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Call in',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark)),
              ),
            ),
        ],
      ),
    );
  }
}
