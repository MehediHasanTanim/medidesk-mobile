import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../data/models/patient_model.dart';
import '../providers/patient_providers.dart';

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchCtrl = TextEditingController();
  int _filterIdx = 0;

  static const _filters = ['All', 'New', 'Chronic', 'Pediatric'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(patientSearchQueryProvider);
    final patientsAsync = ref.watch(
      patientListProvider(searchQuery: searchQuery.isEmpty ? null : searchQuery),
    );
    final tt = Theme.of(context).textTheme;

    return OfflineBanner(
      child: Scaffold(
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
                      child: Text('Patients',
                          style: tt.headlineLarge),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/patients/new'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (q) =>
                        ref.read(patientSearchQueryProvider.notifier).state = q,
                    decoration: const InputDecoration(
                      hintText: 'Search by name, phone, ID',
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.muted),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.asMap().entries.map((e) {
                      final selected = _filterIdx == e.key;
                      return Padding(
                        padding: EdgeInsets.only(right: e.key < _filters.length - 1 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _filterIdx = e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.ink : AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected ? AppColors.ink : AppColors.line,
                              ),
                            ),
                            child: Text(
                              e.key == 0
                                  ? 'All · ${patientsAsync.valueOrNull?.length ?? 0}'
                                  : e.value,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.ink2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: patientsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return EmptyStateView(
                        message: searchQuery.isEmpty
                            ? 'No patients yet.\nTap + to register a new patient.'
                            : 'No patients match "$searchQuery".',
                        icon: Icons.person_search,
                        actionLabel: searchQuery.isEmpty ? 'Add Patient' : null,
                        onAction: searchQuery.isEmpty
                            ? () => context.push('/patients/new')
                            : null,
                      );
                    }
                    return _PatientListView(patients: list);
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) => ErrorView(message: e.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientListView extends StatelessWidget {
  const _PatientListView({required this.patients});
  final List<Patient> patients;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
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
      child: ListView.separated(
        shrinkWrap: false,
        padding: EdgeInsets.zero,
        itemCount: patients.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 14, endIndent: 14),
        itemBuilder: (ctx, i) => _PatientRow(patient: patients[i]),
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.patient});
  final Patient patient;

  Color get _avatarColor {
    final colors = [
      const Color(0xFFF3A847),
      const Color(0xFF5BA9C4),
      const Color(0xFFA07ED4),
      const Color(0xFFE07189),
      const Color(0xFF7EAF80),
      const Color(0xFF5E8FB8),
    ];
    return colors[patient.fullName.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final initials = patient.fullName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();

    final meta = [
      if (patient.ageYears != null) '${patient.ageYears} yrs',
      if (patient.gender == 'M') 'Male' else if (patient.gender == 'F') 'Female' else 'Other',
    ].join(' · ');

    return InkWell(
      onTap: () => context.push('/patients/${patient.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _avatarColor.withValues(alpha: 0.18),
              child: Text(initials,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _avatarColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.fullName, style: tt.titleSmall),
                  const SizedBox(height: 2),
                  Text(meta, style: tt.labelSmall?.copyWith(letterSpacing: 0)),
                ],
              ),
            ),
            if (patient.allergies.isNotEmpty)
              const _StatusChip(
                  label: 'Allergy',
                  bg: AppColors.dangerSoft,
                  fg: AppColors.error),
            if (patient.chronicDiseases.isNotEmpty)
              _StatusChip(
                  label: patient.chronicDiseases.first,
                  bg: AppColors.warningSoft,
                  fg: const Color(0xFF7A5316)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.label, required this.bg, required this.fg});
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
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
