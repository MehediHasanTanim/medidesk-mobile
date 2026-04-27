import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController(text: 'dr.mehta');
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _loading = false);
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),

              // Logo
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MediDesk',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Clinic OS',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Welcome
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.displayLarge,
                  children: const [
                    TextSpan(text: 'Welcome back,\n'),
                    TextSpan(
                      text: 'Dr. Mehta',
                      style: TextStyle(color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your day',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Username
              Text(
                'USERNAME',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _userCtrl,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  prefixText: '@  ',
                  prefixStyle: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              Text(
                'PASSWORD',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••••',
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    child: Text(
                      _obscure ? 'Show' : 'Hide',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign in button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign in securely',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Biometric
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.fingerprint, size: 18),
                  label: const Text('Use biometric · Face ID'),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall,
                    children: const [
                      TextSpan(text: "Don't have a clinic account? "),
                      TextSpan(
                        text: 'Get started',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
