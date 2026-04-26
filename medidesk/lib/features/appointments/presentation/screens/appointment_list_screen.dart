import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  int _dayIdx = 1; // Tuesday selected

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _dates = ['13', '14', '15', '16', '17', '18'];

  static const _slots = [
    _Slot('09:00', 'Priya Sharma', 'Follow-up', Color(0xFF1AA37A), false, 'done'),
    _Slot('09:20', 'Rahul Verma', 'New · Fever', Color(0xFFF3A847), false, 'now'),
    _Slot('09:40', 'Anita Kapoor', 'Lab review', Color(0xFF5BA9C4), false, null),
    _Slot('10:00', null, null, Color(0xFFCFDDD2), true, null),
    _Slot('10:20', 'Vikram Singh', 'Diabetic', Color(0xFFA07ED4), false, null),
    _Slot('10:40', 'Meera Joshi', 'Antenatal', Color(0xFF7EAF80), false, null),
  ];

  @override
  Widget build(BuildContext context) {
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tune, size: 16, color: AppColors.ink),
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
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Day selector
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: List.generate(6, (i) {
                  final selected = i == _dayIdx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _dayIdx = i),
                      child: Container(
                        margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _days[i],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: selected
                                    ? Colors.white.withOpacity(0.7)
                                    : AppColors.ink2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _dates[i],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color:
                                    selected ? Colors.white : AppColors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 14),

            // Slots
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 80),
                itemCount: _slots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _SlotRow(slot: _slots[i]),
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
}

class _Slot {
  const _Slot(this.time, this.name, this.note, this.color, this.isEmpty,
      this.state);
  final String time;
  final String? name;
  final String? note;
  final Color color;
  final bool isEmpty;
  final String? state; // 'done' | 'now' | null
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot});
  final _Slot slot;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initials = slot.name != null
        ? slot.name!.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Time column
        SizedBox(
          width: 54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.time,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: AppColors.ink)),
              Text('20 min',
                  style: tt.labelSmall?.copyWith(letterSpacing: 0)),
            ],
          ),
        ),

        // Card with left color rail
        Expanded(
          child: Stack(
            children: [
              // Color rail
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: slot.color.withOpacity(slot.isEmpty ? 0.4 : 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Slot content
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: slot.isEmpty
                        ? AppColors.surface2
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: slot.isEmpty
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.ink.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                    border: slot.isEmpty
                        ? Border.all(
                            color: AppColors.line2, style: BorderStyle.solid)
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (!slot.isEmpty)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: slot.color.withOpacity(0.2),
                          child: Text(initials,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: slot.color)),
                        ),
                      if (!slot.isEmpty) const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.name ?? '(open slot)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: slot.isEmpty
                                      ? AppColors.muted
                                      : AppColors.ink),
                            ),
                            if (slot.note != null)
                              Text(slot.note!,
                                  style: tt.labelSmall
                                      ?.copyWith(letterSpacing: 0)),
                          ],
                        ),
                      ),
                      _SlotChip(state: slot.state, isEmpty: slot.isEmpty),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({this.state, required this.isEmpty});
  final String? state;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (state == 'done') {
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
    if (state == 'now') {
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
                color: Color(0xFF22C97C),
                shape: BoxShape.circle,
              ),
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
    if (isEmpty) {
      return const Text('+ Book',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark));
    }
    return const SizedBox.shrink();
  }
}
