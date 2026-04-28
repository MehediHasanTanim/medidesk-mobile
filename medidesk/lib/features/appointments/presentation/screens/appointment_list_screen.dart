import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointment_providers.dart';

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() =>
      _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  late DateTime _weekStart;
  late List<DateTime> _week;

  @override
  void initState() {
    super.initState();
    _buildWeek(ref.read(selectedDateProvider));
  }

  void _buildWeek(DateTime anchor) {
    // Start from Monday of the anchor's week
    final dow = anchor.weekday; // 1=Mon … 7=Sun
    _weekStart = anchor.subtract(Duration(days: dow - 1));
    _week = List.generate(6, (i) => _weekStart.add(Duration(days: i)));
  }

  void _selectDay(DateTime day) {
    ref.read(selectedDateProvider.notifier).state = day;
    setState(() => _buildWeek(day));
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final appointmentsAsync =
        ref.watch(appointmentsByDateProvider(selectedDate));
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Schedule', style: tt.headlineLarge),
                  ),
                  GestureDetector(
                    onTap: () => _selectDay(DateTime.now()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text('Today',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push('/appointments/new'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Day selector (6-day rolling week Mon–Sat)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: List.generate(_week.length, (i) {
                  final day = _week[i];
                  final selected = _isSameDay(day, selectedDate);
                  final isToday = _isSameDay(day, DateTime.now());
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDay(day),
                      child: Container(
                        margin: EdgeInsets.only(right: i < _week.length - 1 ? 4 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(day).substring(0, 3).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.ink2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.ink2,
                                  ),
                                ),
                                if (isToday && !selected)
                                  Positioned(
                                    bottom: -2,
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Date label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                DateFormat('EEEE, MMMM d').format(selectedDate),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted),
              ),
            ),

            const SizedBox(height: 8),

            // Appointment slots
            Expanded(
              child: appointmentsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.error)),
                ),
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 48, color: AppColors.muted),
                          const SizedBox(height: 12),
                          Text('No appointments',
                              style: tt.titleMedium
                                  ?.copyWith(color: AppColors.muted)),
                          const SizedBox(height: 4),
                          const Text('Tap + to book one',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.muted)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 80),
                    itemCount: appointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _AppointmentRow(appointment: appointments[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/appointments/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.appointment});
  final Appointment appointment;

  static const _statusColors = {
    'scheduled': Color(0xFF5BA9C4),
    'confirmed': Color(0xFF1AA37A),
    'in_queue': Color(0xFFF3A847),
    'in_progress': Color(0xFFA07ED4),
    'completed': Color(0xFF1AA37A),
    'cancelled': Color(0xFFE07189),
    'no_show': Color(0xFFB0B0B0),
  };

  Color get _color =>
      _statusColors[appointment.status] ?? const Color(0xFF5BA9C4);

  String get _statusLabel => switch (appointment.status) {
        'scheduled' => 'Scheduled',
        'confirmed' => 'Confirmed',
        'in_queue' => 'In queue',
        'in_progress' => 'In progress',
        'completed' => 'Done',
        'cancelled' => 'Cancelled',
        'no_show' => 'No show',
        _ => appointment.status,
      };

  String get _typeLabel => switch (appointment.appointmentType) {
        'new' => 'New',
        'follow_up' => 'Follow-up',
        'walk_in' => 'Walk-in',
        _ => appointment.appointmentType,
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDone = appointment.status == 'completed';
    final isCancelled = appointment.status == 'cancelled';

    return GestureDetector(
      onTap: () => context.push('/appointments/${appointment.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time column
          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimeDisplay(scheduledAt: appointment.scheduledAt),
                Text('· $_typeLabel',
                    style: tt.labelSmall?.copyWith(
                        letterSpacing: 0,
                        color: isCancelled ? AppColors.muted : null)),
              ],
            ),
          ),

          // Card with left color rail
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          _color.withValues(alpha: isCancelled ? 0.3 : 1.0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? AppColors.surface2
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isCancelled
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _color.withValues(alpha: 0.18),
                          child: Text(
                            _initials(appointment.patientId),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _color),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patient ${appointment.patientId.substring(0, 6)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isCancelled
                                        ? AppColors.muted
                                        : AppColors.ink),
                              ),
                              if (appointment.notes.isNotEmpty)
                                Text(appointment.notes,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.labelSmall
                                        ?.copyWith(letterSpacing: 0)),
                            ],
                          ),
                        ),
                        _StatusChip(
                          status: appointment.status,
                          label: _statusLabel,
                          color: _color,
                          isDone: isDone,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String id) => id.substring(0, 2).toUpperCase();
}

class _TimeDisplay extends StatelessWidget {
  const _TimeDisplay({required this.scheduledAt});
  final String scheduledAt;

  @override
  Widget build(BuildContext context) {
    try {
      final dt = DateTime.parse(scheduledAt).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return Text('$hh:$mm',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: AppColors.ink));
    } catch (_) {
      return const Text('--:--',
          style: TextStyle(fontSize: 13, color: AppColors.muted));
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.label,
    required this.color,
    required this.isDone,
  });
  final String status, label;
  final Color color;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text('Done',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark)),
      );
    }
    if (status == 'in_progress') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF22C97C), shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            const Text('Now',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      );
    }
    if (status == 'cancelled' || status == 'no_show') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.error)),
      );
    }
    return const SizedBox.shrink();
  }
}
