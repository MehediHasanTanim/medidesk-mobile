import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _periodIdx = 0;
  static const _periods = ['Today', 'Week', 'Month'];

  // 13-day visit bar data (percentages)
  static const _bars = [40, 55, 70, 48, 82, 90, 62, 75, 58, 68, 80, 95, 72];

  static const _kpis = [
    _Kpi('Patients', '22', '↑ 12% vs avg', AppColors.primaryDark),
    _Kpi('Revenue', '৳38.4k', '↑ 8%', AppColors.primaryDark),
    _Kpi('Avg wait', '16 min', '↑ 4 min', AppColors.error),
    _Kpi('Repeat rate', '68%', '↔ stable', AppColors.muted),
  ];

  static const _diagnoses = [
    _Diagnosis('Acute URTI', 32, Color(0xFF1AA37A)),
    _Diagnosis('Hypertension', 24, Color(0xFF5BA9C4)),
    _Diagnosis('Diabetes type II', 18, Color(0xFFA07ED4)),
    _Diagnosis('Gastritis', 12, Color(0xFFF3A847)),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text('Insights',
                                style: tt.headlineLarge)),
                        const _OutlineChip(label: 'May ▾'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _periods.asMap().entries.map((e) {
                        final sel = _periodIdx == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _periodIdx = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.ink
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(999),
                                border: Border.all(
                                    color: sel
                                        ? AppColors.ink
                                        : AppColors.line),
                              ),
                              child: Text(e.value,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.ink2)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // KPI grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: _kpis.map((k) => _KpiCard(kpi: k)).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Bar chart
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Visits · last 13 days',
                                  style: tt.titleSmall),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              child: const Text('+22%',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _bars.asMap().entries.map((e) {
                              final isLast =
                                  e.key == _bars.length - 1;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: FractionallySizedBox(
                                          heightFactor: e.value / 100,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isLast
                                                  ? AppColors.primary
                                                  : AppColors.primarySoft,
                                              borderRadius:
                                                  const BorderRadius
                                                      .vertical(
                                                top: Radius.circular(6),
                                                bottom:
                                                    Radius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${e.key + 1}',
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: AppColors.muted,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Top diagnoses
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top diagnoses', style: tt.titleSmall),
                        const SizedBox(height: 10),
                        ..._diagnoses.asMap().entries.map((e) => Column(
                              children: [
                                if (e.key > 0)
                                  const Divider(height: 16),
                                _DiagnosisRow(d: e.value),
                              ],
                            )),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
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
        child: child,
      );
}

class _Kpi {
  const _Kpi(this.label, this.value, this.trend, this.trendColor);
  final String label, value, trend;
  final Color trendColor;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});
  final _Kpi kpi;

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
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(kpi.label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(kpi.value,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(kpi.trend,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kpi.trendColor)),
        ],
      ),
    );
  }
}

class _Diagnosis {
  const _Diagnosis(this.name, this.percent, this.color);
  final String name;
  final int percent;
  final Color color;
}

class _DiagnosisRow extends StatelessWidget {
  const _DiagnosisRow({required this.d});
  final _Diagnosis d;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(d.name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
            Text('${d.percent}%',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: d.percent / 100,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation<Color>(d.color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2)),
    );
  }
}
