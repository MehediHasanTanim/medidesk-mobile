import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class ConsultationDetailScreen extends StatefulWidget {
  const ConsultationDetailScreen({super.key, required this.localId});
  final String localId;

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen>
    with TickerProviderStateMixin {
  bool _recording = true;
  late final AnimationController _waveCtrl;
  late final AnimationController _dotCtrl;

  // Elapsed timer
  final _stopwatch = Stopwatch()..start();
  late final _timerStream = Stream<int>.periodic(
    const Duration(seconds: 1),
    (i) => i,
  );

  static const _vitals = [
    ('BP', '128/82', false),
    ('HR', '86', false),
    ('Temp', '38.4', true),
    ('SpO₂', '98', false),
  ];

  static const _quickAdd = [
    '+ Diagnosis',
    '+ Rx',
    '+ Tests',
    '+ Note',
    '+ Follow-up',
  ];

  static const _waveHeights = [3, 7, 5, 9, 4, 8, 6, 10, 4, 7, 5, 9, 3, 8, 6, 4, 8, 5, 7, 3];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _dotCtrl.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  String get _elapsedLabel {
    final s = _stopwatch.elapsed.inSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar with timer
            _ConsultationAppBar(
              onBack: () => Navigator.of(context).pop(),
              elapsedStream: _timerStream,
              getLabel: () => _elapsedLabel,
            ),

            // Scrollable body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                children: [
                  // Patient card
                  _card(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0x305ba9c4),
                          child: Text('RV',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF5BA9C4))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rahul Verma', style: tt.titleMedium),
                              Text('28 · M · O+ · #2149',
                                  style: tt.labelSmall
                                      ?.copyWith(letterSpacing: 0)),
                            ],
                          ),
                        ),
                        const _DangerChip(label: 'Penicillin allergy'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Vitals grid
                  Row(
                    children: _vitals.asMap().entries.map((e) {
                      final (label, value, danger) = e.value;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: e.key < _vitals.length - 1 ? 8 : 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              children: [
                                Text(label,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.muted,
                                        letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(value,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: danger
                                            ? AppColors.error
                                            : AppColors.ink)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Chief complaint
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text('Chief complaint',
                                    style: tt.titleSmall)),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('Edit',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.ink2,
                                height: 1.5),
                            children: [
                              TextSpan(
                                  text:
                                      'Fever × 3 days, peak 38.9°C. Productive cough, mild sore throat. No travel history. '),
                              TextSpan(
                                  text: '+ runny nose',
                                  style: TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // AI scribe card
                  AnimatedBuilder(
                    animation: _dotCtrl,
                    builder: (_, __) => Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Listening · transcribing',
                                  style: tt.titleSmall?.copyWith(
                                      color: AppColors.primaryDark,
                                      fontSize: 13)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: AppColors.primaryDark
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Text('AI scribe',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '"…throat looks mildly inflamed, no exudate. Lungs — bilateral crackles at the base. I\'d say upper resp tract infection, likely viral, but let\'s rule out…"',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ink2,
                                height: 1.55,
                                fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 10),
                          // Waveform bars
                          AnimatedBuilder(
                            animation: _waveCtrl,
                            builder: (_, __) => SizedBox(
                              height: 24,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _waveHeights.map((h) {
                                  final animated = h *
                                      2 *
                                      (0.6 +
                                          0.4 * _waveCtrl.value *
                                              (h / 10));
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      height: animated.clamp(2.0, 20.0),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.5 + (h / 20)),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick add chips
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('QUICK ADD',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                              letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickAdd
                            .map((q) => GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border: Border.all(
                                          color: AppColors.line),
                                    ),
                                    child: Text(q,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink2)),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
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
                  GestureDetector(
                    onTap: () => setState(() => _recording = !_recording),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _recording
                            ? AppColors.error
                            : AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => context.push(
                            '/prescriptions/${widget.localId}/form'),
                        child: const Text('Finish & prescribe'),
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

  Widget _card({required Widget child}) => Container(
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
        child: child,
      );
}

// ── AppBar with live timer ────────────────────────────────
class _ConsultationAppBar extends StatefulWidget {
  const _ConsultationAppBar({
    required this.onBack,
    required this.elapsedStream,
    required this.getLabel,
  });
  final VoidCallback onBack;
  final Stream<int> elapsedStream;
  final String Function() getLabel;

  @override
  State<_ConsultationAppBar> createState() => _ConsultationAppBarState();
}

class _ConsultationAppBarState extends State<_ConsultationAppBar> {
  String _label = '00:00';

  @override
  void initState() {
    super.initState();
    widget.elapsedStream.listen((_) {
      if (mounted) setState(() => _label = widget.getLabel());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            color: AppColors.ink,
          ),
          Expanded(
            child: Column(
              children: [
                const Text('CONSULTATION',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        letterSpacing: 1)),
                Text(_label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, size: 18),
            color: AppColors.ink,
          ),
        ],
      ),
    );
  }
}

class _DangerChip extends StatelessWidget {
  const _DangerChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
}
