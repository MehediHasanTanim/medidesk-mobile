import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PrescriptionFormScreen extends StatefulWidget {
  const PrescriptionFormScreen({super.key, required this.prescriptionId});
  final String prescriptionId;

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  static const _medications = [
    _Med('Azithromycin', '500 mg · 1 tab · OD', 'After food · 5 days',
        Color(0xFF1AA37A)),
    _Med('Paracetamol', '650 mg · 1 tab · TDS', 'SOS for fever > 38°C',
        Color(0xFF5BA9C4)),
    _Med('Levocetirizine', '5 mg · 1 tab · HS', 'At bedtime · 5 days',
        Color(0xFFA07ED4)),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            _AppBar(prescriptionId: widget.prescriptionId),

            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                children: [
                  // Patient header
                  _flatCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xff5ba9c420),
                          child: Text('RV',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5BA9C4))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rahul Verma · 28y · M',
                                  style: tt.titleSmall?.copyWith(fontSize: 13)),
                              const Text('⚠ Penicillin allergy',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Diagnosis
                  _sectionLabel('DIAGNOSIS'),
                  const SizedBox(height: 6),
                  _flatCard(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        const _PrimaryChip(label: 'Acute URTI · J06.9'),
                        const _PrimaryChip(label: 'Pyrexia · R50.9'),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: const Text('+ add',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Medications
                  _sectionLabel('MEDICATIONS · ${_medications.length}'),
                  const SizedBox(height: 6),
                  ..._medications.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MedCard(med: m),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add medication'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Advice
                  _sectionLabel('ADVICE'),
                  const SizedBox(height: 6),
                  _flatCard(
                    child: const Text(
                      'Hydrate well · steam inhalation 2× a day · review in 5 days if fever persists.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink2,
                          height: 1.55),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.receipt_long_outlined,
                          color: AppColors.primaryDark, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Sign & send via SMS'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 1));

  Widget _flatCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );
}

// ── AppBar ────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  const _AppBar({required this.prescriptionId});
  final String prescriptionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.ink),
          ),
          Expanded(
            child: Text('New Rx',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text('Draft',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Medication card ───────────────────────────────────────
class _Med {
  const _Med(this.name, this.dosage, this.frequency, this.color);
  final String name, dosage, frequency;
  final Color color;
}

class _MedCard extends StatelessWidget {
  const _MedCard({required this.med});
  final _Med med;

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
            color: AppColors.ink.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color rail
          Container(
            width: 6,
            height: 56,
            decoration: BoxDecoration(
              color: med.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: tt.titleSmall),
                const SizedBox(height: 2),
                Text(med.dosage,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink2,
                        fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Text(med.frequency, style: tt.labelSmall?.copyWith(letterSpacing: 0)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz,
                size: 18, color: AppColors.muted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Chips ─────────────────────────────────────────────────
class _PrimaryChip extends StatelessWidget {
  const _PrimaryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark)),
    );
  }
}
