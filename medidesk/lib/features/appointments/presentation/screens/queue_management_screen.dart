import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QueueManagementScreen extends StatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _calling = false;
  bool _tick = false;

  static const _queue = [
    _QueueItem(7, 'Rahul Verma', 'In room', Color(0xFF5BA9C4), 'now'),
    _QueueItem(8, 'Priya Sharma', 'Waiting · 4 min', Color(0xFFF3A847), 'next'),
    _QueueItem(9, 'Anita Kapoor', 'Waiting · 12 min', Color(0xFFA07ED4), null),
    _QueueItem(10, 'Vikram Singh', 'Waiting · 18 min', Color(0xFFE07189), null,
        longWait: true),
    _QueueItem(11, 'Meera Joshi', 'Waiting · 24 min', Color(0xFF7EAF80), null,
        longWait: true),
  ];

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

  Future<void> _callNext() async {
    setState(() => _calling = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _calling = false;
      _tick = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _tick = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Dark green header
          Container(
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
                        const Row(
                          children: [
                            _GlassIconBtn(icon: Icons.tune),
                            SizedBox(width: 8),
                            _GlassIconBtn(icon: Icons.more_horiz),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C97C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('LIVE QUEUE',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xCCFFFFFF),
                                        letterSpacing: 1)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text('14 waiting',
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.6)),
                          ],
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Avg wait',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xB3FFFFFF))),
                            Text('16 min',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 80),
              children: [
                // Now serving card
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
                  child: Row(
                    children: [
                      // Pulsing avatar
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) {
                          final v = _pulse.value;
                          return Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primarySoft,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5 * (1 - v)),
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
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text('#07',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
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
                            Text('Rahul Verma',
                                style: Theme.of(context).textTheme.titleMedium),
                            const Text('In room · 6 min',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _calling ? null : _callNext,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
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
                          child: Text(
                            _calling
                                ? 'Ringing…'
                                : _tick
                                    ? '✓ Done'
                                    : 'Call next',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Text('UP NEXT',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        letterSpacing: 1)),
                const SizedBox(height: 8),

                ..._queue.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _QueueRow(item: item),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _QueueItem {
  const _QueueItem(this.number, this.name, this.status, this.color, this.state,
      {this.longWait = false});
  final int number;
  final String name, status;
  final Color color;
  final String? state;
  final bool longWait;
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.item});
  final _QueueItem item;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initials = item.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();
    final isNext = item.state == 'next';

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
              color:
                  isNext ? AppColors.primarySoft : AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('#${item.number}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isNext
                          ? AppColors.primaryDark
                          : AppColors.ink2)),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: item.color.withValues(alpha: 0.2),
            child: Text(initials,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: tt.titleSmall?.copyWith(fontSize: 13)),
                Text(item.status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.longWait
                            ? AppColors.error
                            : AppColors.muted)),
              ],
            ),
          ),
          if (isNext)
            const _SmallChip(label: 'Next', bg: AppColors.primarySoft, fg: AppColors.primaryDark),
          if (item.longWait)
            const _SmallChip(label: 'Long wait', bg: AppColors.dangerSoft, fg: AppColors.error),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
