import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.localId});
  final String localId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  int _paymentIdx = 0; // 0 = UPI selected

  static const _lineItems = [
    ('Consultation', '৳500'),
    ('CBC + CRP', '৳770'),
    ('Medications · 3 items', '৳200'),
  ];

  static const _methods = [
    _PayMethod('UPI', 'bKash · Nagad'),
    _PayMethod('Cash', 'Quick'),
    _PayMethod('Card', 'POS terminal'),
    _PayMethod('Insurance', 'Cashless'),
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
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back,
                        size: 18, color: AppColors.ink),
                  ),
                  Expanded(
                    child: Text('Invoice #4421', style: tt.titleMedium),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz,
                        size: 18, color: AppColors.ink),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                children: [
                  // Total card
                  _card(
                    child: Column(
                      children: [
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('TOTAL DUE',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.muted,
                                          letterSpacing: 1)),
                                  SizedBox(height: 4),
                                  Text('৳1,470',
                                      style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                          letterSpacing: -1,
                                          fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Color(0xff5ba9c420),
                              child: Text('RV',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF5BA9C4))),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        ..._lineItems.map((r) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.$1,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.ink2)),
                                  Text(r.$2,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                          color: AppColors.ink)),
                                ],
                              ),
                            )),
                        const Divider(height: 16),
                        const _InvoiceRow(label: 'GST · 0%', value: '৳0',
                            labelColor: AppColors.muted),
                        const Divider(height: 16),
                        const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                            Text('৳1,470',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: AppColors.ink)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('PAYMENT METHOD',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),

                  // Payment methods 2x2 grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: _methods.asMap().entries.map((e) {
                      final sel = _paymentIdx == e.key;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _paymentIdx = e.key),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(e.value.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink)),
                                    Text(e.value.description,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              if (sel)
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 12),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Send link'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Collect ৳1,470'),
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
        padding: const EdgeInsets.all(18),
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
        child: child,
      );
}

class _PayMethod {
  const _PayMethod(this.name, this.description);
  final String name, description;
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow(
      {required this.label, required this.value, this.labelColor});
  final String label, value;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: labelColor ?? AppColors.ink2)),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.muted)),
      ],
    );
  }
}
