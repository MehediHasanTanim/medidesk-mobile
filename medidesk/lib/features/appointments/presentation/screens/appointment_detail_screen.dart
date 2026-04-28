import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointment_providers.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.localId});
  final String localId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appointmentDetailProvider(localId));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorView(message: e.toString())),
      data: (appt) {
        if (appt == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Appointment')),
            body: const ErrorView(message: 'Appointment not found.'),
          );
        }
        return _DetailView(appointment: appt);
      },
    );
  }
}

class _DetailView extends ConsumerStatefulWidget {
  const _DetailView({required this.appointment});
  final Appointment appointment;

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  Appointment get appt => widget.appointment;

  static const _statusColors = {
    'scheduled': Color(0xFF5BA9C4),
    'confirmed': Color(0xFF1AA37A),
    'in_queue': Color(0xFFF3A847),
    'in_progress': Color(0xFFA07ED4),
    'completed': Color(0xFF1AA37A),
    'cancelled': Color(0xFFE07189),
    'no_show': Color(0xFFB0B0B0),
  };

  Color get _statusColor =>
      _statusColors[appt.status] ?? const Color(0xFF5BA9C4);

  String get _statusLabel => switch (appt.status) {
        'scheduled' => 'Scheduled',
        'confirmed' => 'Confirmed',
        'in_queue' => 'In Queue',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        'no_show' => 'No Show',
        _ => appt.status,
      };

  String get _typeLabel => switch (appt.appointmentType) {
        'new' => 'New Patient',
        'follow_up' => 'Follow-up',
        'walk_in' => 'Walk-in',
        _ => appt.appointmentType,
      };

  String get _scheduledDisplay {
    try {
      final dt = DateTime.parse(appt.scheduledAt).toLocal();
      return DateFormat('EEE, MMM d · h:mm a').format(dt);
    } catch (_) {
      return appt.scheduledAt;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    await ref
        .read(updateAppointmentStatusNotifierProvider.notifier)
        .execute(appt.id, newStatus);
    final state = ref.read(updateAppointmentStatusNotifierProvider);
    if (!mounted) return;
    state.whenOrNull(
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Cancel appointment?',
      message: 'This appointment will be soft-deleted and synced to the server.',
      confirmLabel: 'Cancel appointment',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(deleteAppointmentNotifierProvider.notifier)
        .execute(appt.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(updateAppointmentStatusNotifierProvider).isLoading ||
            ref.watch(deleteAppointmentNotifierProvider).isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Gradient header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1AA37A), Color(0xFF0E7C5D)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _GlassBtn(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.of(context).pop()),
                          Row(
                            children: [
                              _GlassBtn(
                                icon: Icons.edit_outlined,
                                onTap: () => context
                                    .push('/appointments/${appt.id}/edit'),
                              ),
                              const SizedBox(width: 8),
                              _GlassBtn(
                                icon: Icons.delete_outline,
                                onTap: _delete,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: _statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scheduledDisplay,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _typeLabel,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xCCFFFFFF)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Detail content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 80),
                children: [
                  _InfoCard(
                    title: 'Details',
                    rows: [
                      _InfoRow(
                          label: 'Patient ID',
                          value: appt.patientId.substring(0, 8)),
                      _InfoRow(
                          label: 'Doctor ID',
                          value: appt.doctorId.substring(0, 8)),
                      if (appt.chamberId != null)
                        _InfoRow(
                            label: 'Chamber',
                            value: appt.chamberId!.substring(0, 8)),
                      if (appt.tokenNumber != null)
                        _InfoRow(
                            label: 'Token',
                            value: '#${appt.tokenNumber}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (appt.notes.isNotEmpty)
                    _InfoCard(
                      title: 'Notes',
                      rows: [
                        _InfoRow(label: '', value: appt.notes),
                      ],
                    ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Sync',
                    rows: [
                      _InfoRow(label: 'Status', value: appt.syncStatus),
                      if (appt.serverId != null)
                        _InfoRow(
                            label: 'Server ID',
                            value: appt.serverId!.substring(0, 8)),
                    ],
                  ),

                  if (appt.status == 'scheduled' ||
                      appt.status == 'confirmed') ...[
                    const SizedBox(height: 24),
                    const Text('ACTIONS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    _ActionButton(
                      label: 'Check in → Add to queue',
                      icon: Icons.queue,
                      color: AppColors.primary,
                      onTap: () => _updateStatus('in_queue'),
                    ),
                    const SizedBox(height: 8),
                    _ActionButton(
                      label: 'Mark as No Show',
                      icon: Icons.person_off_outlined,
                      color: AppColors.muted,
                      onTap: () => _updateStatus('no_show'),
                    ),
                  ],

                  if (appt.status == 'in_queue') ...[
                    const SizedBox(height: 24),
                    const Text('ACTIONS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    _ActionButton(
                      label: 'Start Consultation',
                      icon: Icons.medical_services_outlined,
                      color: AppColors.primary,
                      onTap: () {
                        _updateStatus('in_progress');
                        context.push('/consultations/${appt.id}');
                      },
                    ),
                  ],

                  if (appt.status == 'in_progress') ...[
                    const SizedBox(height: 24),
                    _ActionButton(
                      label: 'Mark Complete',
                      icon: Icons.check_circle_outline,
                      color: AppColors.primary,
                      onTap: () => _updateStatus('completed'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────

class _GlassBtn extends StatelessWidget {
  const _GlassBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const Divider(height: 18),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted)),
            ),
          ],
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
