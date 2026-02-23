import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_fonts.dart';
import '../../services/firebase/firebase_auth_service.dart';
import '../../services/firebase/google_auth_service.dart';
import '../../utils/validators.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final authService = Get.find<FirebaseAuthService>();
      await authService.signUpWithEmailPassword(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      await authService.updateDisplayName(_nameCtrl.text.trim());
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _googleSignup() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Get.find<GoogleAuthService>().signInWithGoogle();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl, horizontal: AppSpacing.l),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        size: 64, color: Colors.white),
                    const SizedBox(height: AppSpacing.m),
                    Text('Budget Buddy',
                        style: AppFonts.h2.copyWith(color: Colors.white)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Start your financial journey',
                        style: AppFonts.bodyMedium.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.m),
                      Text('Create Account', style: AppFonts.h4),
                      const SizedBox(height: AppSpacing.s),
                      Text('Sign up to get started',
                          style: AppFonts.bodyMedium.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: AppSpacing.l),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.s),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                          ),
                          child: Text(_error!,
                              style: AppFonts.bodySmall.copyWith(color: AppColors.error)),
                        ),
                        const SizedBox(height: AppSpacing.m),
                      ],
                      TextFormField(
                        controller: _nameCtrl,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        validator: Validators.name,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outlined),
                        ),
                        validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      FilledButton(
                        onPressed: _loading ? null : _signup,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create Account'),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                            child: Text('OR',
                                style: AppFonts.caption.copyWith(color: colors.onSurfaceVariant)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.l),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _googleSignup,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ', style: AppFonts.bodyMedium),
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Log In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
