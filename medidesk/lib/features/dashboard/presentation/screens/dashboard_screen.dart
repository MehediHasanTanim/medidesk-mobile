import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _upNext = [
    _UpNextItem('Priya Sharma', '09:40 · Follow-up', 'Q · #08', Color(0xFFF3A847)),
    _UpNextItem('Rahul Verma', '10:00 · New · Fever', 'Q · #09', Color(0xFF5BA9C4)),
    _UpNextItem('Anita Kapoor', '10:20 · Lab review', 'Q · #10', Color(0xFFA07ED4)),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, tt)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 14),
                  _QueueCard(),
                  const SizedBox(height: 14),
                  _KpiRow(),
                  const SizedBox(height: 14),
                  const _UpNextSection(items: _upNext),
                  const SizedBox(height: 14),
                  _QuickActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySoft,
            child: Text('DM',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tuesday, 14 May',
                    style: tt.labelSmall?.copyWith(
                        color: AppColors.muted, letterSpacing: 0)),
                Text('Hi, Dr. Mehta 👋',
                    style: tt.titleMedium),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_outlined,
                    size: 18, color: AppColors.ink),
              ),
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Live queue card ───────────────────────────────────────
class _QueueCard extends StatefulWidget {
  @override
  State<_QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends State<_QueueCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dot;

  @override
  void initState() {
    super.initState();
    _dot = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkCardStart, AppColors.darkCardEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCardStart.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TODAY\'S QUEUE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xB3FFFFFF),
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: '14',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1),
                    ),
                    TextSpan(
                      text: ' / 22',
                      style: TextStyle(
                          fontSize: 16,
                          color: Color(0x99FFFFFF),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _dot,
                    builder: (_, __) => Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C97C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Now: #07',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xD9FFFFFF),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 14 / 22,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF7EE3BF)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _DarkBtn(
                label: 'Call next',
                onTap: () => context.push('/appointments/queue'),
              ),
              const SizedBox(width: 8),
              _DarkBtn(label: 'Pause queue', outlined: true, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkBtn extends StatelessWidget {
  const _DarkBtn(
      {required this.label, this.outlined = false, required this.onTap});
  final String label;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: outlined
              ? Border.all(color: Colors.white.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

// ── KPI row ───────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _KpiCard(label: 'Appointments', value: '22', sub: '+3 walk-ins', subColor: AppColors.primaryDark)),
        SizedBox(width: 10),
        Expanded(child: _KpiCard(label: 'Revenue', value: '৳38.4k', sub: '4 pending', subColor: AppColors.muted)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
  });
  final String label, value, sub;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
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
          Text(label.toUpperCase(),
              style: tt.labelSmall),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: subColor)),
        ],
      ),
    );
  }
}

// ── Up-next section ───────────────────────────────────────
class _UpNextSection extends StatelessWidget {
  const _UpNextSection({required this.items});
  final List<_UpNextItem> items;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Up next', style: tt.titleSmall),
            TextButton(
              onPressed: () => context.go('/appointments'),
              child: const Text('See all',
                  style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
        Container(
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
            children: items
                .asMap()
                .entries
                .map((e) => _UpNextRow(
                      item: e.value,
                      isFirst: e.key == 0,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _UpNextItem {
  const _UpNextItem(this.name, this.time, this.token, this.color);
  final String name, time, token;
  final Color color;
}

class _UpNextRow extends StatelessWidget {
  const _UpNextRow({required this.item, required this.isFirst});
  final _UpNextItem item;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        if (!isFirst)
          const Divider(height: 1, indent: 14, endIndent: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: item.color.withValues(alpha: 0.2),
                child: Text(
                  item.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: item.color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: tt.titleSmall?.copyWith(fontSize: 14)),
                    Text(item.time,
                        style: tt.labelSmall?.copyWith(letterSpacing: 0)),
                  ],
                ),
              ),
              _PrimaryChip(label: item.token),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Quick actions ─────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TonalBtn(label: '+ Walk-in', onTap: () => context.push('/appointments/new')),
        _TonalBtn(label: 'Send SMS', onTap: () {}),
        _TonalBtn(label: 'New Rx', onTap: () {}),
      ],
    );
  }
}

class _TonalBtn extends StatelessWidget {
  const _TonalBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark)),
      ),
    );
  }
}

// ── Shared chip ───────────────────────────────────────────
class _PrimaryChip extends StatelessWidget {
  const _PrimaryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark)),
    );
  }
}
