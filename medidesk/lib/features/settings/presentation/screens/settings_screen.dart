import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;
  bool _biometric = true;
  bool _autoBackup = true;
  bool _darkMode = false;

  static const _clinicRows = [
    ('Clinic profile', 'Sai Health, Bandra'),
    ('Staff & roles', '3 members'),
    ('Working hours', 'Mon–Sat · 9–7'),
    ('Templates', '12 saved'),
  ];

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final userName = ref.watch(currentUserNameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Text('Settings', style: tt.headlineLarge),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Doctor profile card
                  Container(
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primarySoft,
                          child: Text(_initials(userName),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(userName,
                                  style: tt.titleMedium),
                              const SizedBox(height: 2),
                              const Text(
                                  'General Physician · BMDC 8841/22',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted)),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  _Badge(label: 'Pro', bg: AppColors.primarySoft, fg: AppColors.primaryDark),
                                  SizedBox(width: 6),
                                  _Badge(label: 'Dhaka', bg: AppColors.surface2, fg: AppColors.ink2),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('CLINIC'),
                  const SizedBox(height: 8),

                  // Clinic rows
                  Container(
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
                      children: _clinicRows.asMap().entries.map((e) {
                        return Column(
                          children: [
                            if (e.key > 0)
                              const Divider(
                                  height: 1, indent: 14, endIndent: 14),
                            InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.only(
                                topLeft: e.key == 0
                                    ? const Radius.circular(20)
                                    : Radius.zero,
                                topRight: e.key == 0
                                    ? const Radius.circular(20)
                                    : Radius.zero,
                                bottomLeft:
                                    e.key == _clinicRows.length - 1
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                bottomRight:
                                    e.key == _clinicRows.length - 1
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(e.value.$1,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: AppColors.ink)),
                                          Text(e.value.$2,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.muted)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: AppColors.muted, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('PREFERENCES'),
                  const SizedBox(height: 8),

                  // Toggle rows
                  Container(
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
                      children: [
                        _ToggleRow(
                          label: 'Notifications',
                          value: _notifications,
                          isFirst: true,
                          onChanged: (v) => setState(() => _notifications = v),
                        ),
                        _ToggleRow(
                          label: 'Biometric login',
                          value: _biometric,
                          onChanged: (v) => setState(() => _biometric = v),
                        ),
                        _ToggleRow(
                          label: 'Auto-backup',
                          value: _autoBackup,
                          onChanged: (v) => setState(() => _autoBackup = v),
                        ),
                        _ToggleRow(
                          label: 'Dark mode',
                          value: _darkMode,
                          isLast: true,
                          onChanged: (v) => setState(() => _darkMode = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick links
                  _sectionLabel('MORE'),
                  const SizedBox(height: 8),
                  Container(
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
                      children: [
                        _LinkRow(
                          icon: Icons.bar_chart_rounded,
                          label: 'Analytics',
                          iconColor: AppColors.secondary,
                          isFirst: true,
                          onTap: () => context.push('/analytics'),
                        ),
                        _LinkRow(
                          icon: Icons.domain_rounded,
                          label: 'Chambers',
                          iconColor: AppColors.primary,
                          onTap: () => context.go('/chambers'),
                        ),
                        _LinkRow(
                          icon: Icons.receipt_long_outlined,
                          label: 'Billing',
                          iconColor: AppColors.warning,
                          isLast: true,
                          onTap: () => context.go('/billing/invoices'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign out
                  _SignOutButton(),
                ]),
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
}

// ── Sign-out button ────────────────────────────────────────
class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(logoutNotifierProvider).isLoading;
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () async {
                await ref.read(logoutNotifierProvider.notifier).execute();
                // Router redirect to /login fires automatically via
                // isAuthenticatedProvider; no manual navigation needed.
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            : const Text('Sign out',
                style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isFirst, isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst)
          const Divider(height: 1, indent: 14, endIndent: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink)),
              ),
              GestureDetector(
                onTap: () => onChanged(!value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? AppColors.primary : AppColors.line2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment:
                        value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isFirst, isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst)
          const Divider(height: 1, indent: 14, endIndent: 14),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
            topRight: isFirst ? const Radius.circular(20) : Radius.zero,
            bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.muted, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
