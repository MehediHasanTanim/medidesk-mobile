import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/models/patient_model.dart';
import '../providers/patient_providers.dart';
import '../widgets/patient_note_list.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.localId});
  final String localId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(localId));
    return patientAsync.when(
      data: (p) {
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Patient')),
            body: const ErrorView(message: 'Patient not found.'),
          );
        }
        return _DetailView(patient: p);
      },
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: ErrorView(message: e.toString())),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.patient});
  final Patient patient;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  static const _tabs = ['Overview', 'Visits', 'Rx', 'Tests', 'Bills'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Patient get p => widget.patient;

  Color get _avatarColor {
    final colors = [
      const Color(0xFFF3A847),
      const Color(0xFF5BA9C4),
      const Color(0xFFA07ED4),
      const Color(0xFFE07189),
    ];
    return colors[p.fullName.length % colors.length];
  }

  String get _initials =>
      p.fullName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Hero header
          _HeroHeader(patient: p, initials: _initials, avatarColor: _avatarColor),

          // Tabs
          Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Row(
                children: _tabs.asMap().entries.map((e) {
                  return GestureDetector(
                    onTap: () => setState(() => _tab.index = e.key),
                    child: AnimatedBuilder(
                      animation: _tab,
                      builder: (_, __) {
                        final sel = _tab.index == e.key;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: sel ? AppColors.ink : AppColors.line,
                            ),
                          ),
                          child: Text(e.value,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : AppColors.ink2,
                              )),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Body
          Expanded(
            child: AnimatedBuilder(
              animation: _tab,
              builder: (_, __) => _tabBody(context),
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A0E1F17),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.push('/consultations/${p.id}'),
                      child: const Text('Start consultation'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () => context.push('/billing/invoices'),
                    icon: const Icon(Icons.receipt_long_outlined,
                        color: AppColors.primaryDark, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody(BuildContext context) {
    if (_tab.index == 0) return _OverviewTab(patient: p);
    return Center(
      child: Text(
        _tabs[_tab.index],
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

// ── Hero gradient header ──────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader(
      {required this.patient, required this.initials, required this.avatarColor});
  final Patient patient;
  final String initials;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (patient.ageYears != null) '${patient.ageYears} yrs',
      if (patient.gender == 'M') 'Male' else if (patient.gender == 'F') 'Female' else 'Other',
      if (patient.patientId != null) '#${patient.patientId}',
    ].join(' · ');

    return Container(
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
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassBtn(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                  _GlassBtn(icon: Icons.more_horiz, onTap: () {}),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: avatarColor.withOpacity(0.3),
                    child: Text(initials,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.fullName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.4)),
                        const SizedBox(height: 2),
                        Text(meta,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xCCFFFFFF))),
                        if (patient.allergies.isNotEmpty ||
                            patient.chronicDiseases.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ...patient.allergies.take(2).map((a) =>
                                    _GlassChip(label: a)),
                                ...patient.chronicDiseases.take(2).map((d) =>
                                    _GlassChip(label: d)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Vitals row — placeholder
              const Row(
                children: [
                  _VitalBox(label: 'BP', value: '—/—', unit: 'mmHg'),
                  SizedBox(width: 10),
                  _VitalBox(label: 'HR', value: '—', unit: 'bpm'),
                  SizedBox(width: 10),
                  _VitalBox(label: 'BMI', value: '—', unit: ''),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

class _VitalBox extends StatelessWidget {
  const _VitalBox({required this.label, required this.value, required this.unit});
  final String label, value, unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xCCFFFFFF),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xB3FFFFFF),
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 80),
      children: [
        const _SectionCard(
          title: 'Recent visits',
          trailing: Text('0 total',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark)),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No visits recorded yet.',
                style: TextStyle(fontSize: 13, color: AppColors.muted)),
          ),
        ),
        const SizedBox(height: 12),
        if (patient.allergies.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Allergies — ${patient.allergies.join(', ')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Check before prescribing.',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF7A5316))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        PatientNoteList(patientLocalId: patient.id),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}
