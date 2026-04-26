import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TestOrderFormScreen extends StatefulWidget {
  const TestOrderFormScreen({super.key, required this.consultationId});
  final String consultationId;

  @override
  State<TestOrderFormScreen> createState() => _TestOrderFormScreenState();
}

class _TestOrderFormScreenState extends State<TestOrderFormScreen> {
  final _searchCtrl = TextEditingController();
  int _filterIdx = 0;
  final Set<int> _selected = {0, 1};

  static const _filters = ['Common', 'Blood', 'Imaging', 'Cardiac'];

  static const _tests = [
    _Test('CBC · Complete blood count', '৳350', 'Lab · same day'),
    _Test('CRP · C-reactive protein', '৳420', 'Lab · same day'),
    _Test('Chest X-Ray PA view', '৳600', 'Imaging · 2 hr'),
    _Test('COVID-19 RT-PCR', '৳980', 'Lab · 6 hr'),
    _Test('Throat swab culture', '৳540', 'Lab · 48 hr'),
  ];
  static const _prices = [350, 420, 600, 980, 540];

  int get _subtotal =>
      _selected.fold(0, (sum, i) => sum + _prices[i]);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
                      child: Text('Order tests', style: tt.titleMedium)),
                  if (_selected.isNotEmpty)
                    _OutlineChip(
                        label: '${_selected.length} selected'),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // Scrollable body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                children: [
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search 320+ tests',
                        prefixIcon: Icon(Icons.search,
                            size: 18, color: AppColors.muted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.asMap().entries.map((e) {
                        final sel = _filterIdx == e.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _filterIdx = e.key),
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
                  ),
                  const SizedBox(height: 14),

                  const Text('SUGGESTED FOR URTI',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),

                  ..._tests.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selected.contains(e.key)
                                ? _selected.remove(e.key)
                                : _selected.add(e.key);
                          }),
                          child: _TestRow(
                            test: e.value,
                            selected: _selected.contains(e.key),
                          ),
                        ),
                      )),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal · ${_selected.length} test${_selected.length == 1 ? '' : 's'}',
                        style: tt.bodySmall,
                      ),
                      Text('৳$_subtotal',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(),
                      child: const Text('Order & add to bill'),
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
}

class _Test {
  const _Test(this.name, this.price, this.turnaround);
  final String name, price, turnaround;
}

class _TestRow extends StatelessWidget {
  const _TestRow({required this.test, required this.selected});
  final _Test test;
  final bool selected;

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
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color:
                  selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.line2,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.name,
                    style: tt.titleSmall?.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(test.turnaround,
                    style: tt.labelSmall?.copyWith(letterSpacing: 0)),
              ],
            ),
          ),
          Text(test.price,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2)),
    );
  }
}
