import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/input_fields.dart';
import 'auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController controller = Get.find<AuthController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      controller.login(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  AppSpacing.l * 2,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // Logo and Welcome Text
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          Text(
                            'Budget Buddy',
                            style: AppFonts.h2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            'Welcome back!',
                            style: AppFonts.bodyLarge.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Email Field
                    AppInputField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.l),

                    // Password Field
                    Obx(() => AppInputField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: _passwordController,
                          obscureText: !controller.isPasswordVisible.value,
                          prefixIcon: Icons.lock_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textMuted,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        )),

                    const SizedBox(height: AppSpacing.s),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppTextButton(
                        text: 'Forgot Password?',
                        onPressed: () {
                          // TODO: Implement forgot password
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Login Button
                    Obx(() => PrimaryButton(
                          text: 'Login',
                          onPressed: _handleLogin,
                          isLoading: controller.isLoading.value,
                          isFullWidth: true,
                        )),

                    const SizedBox(height: AppSpacing.l),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m),
                          child: Text(
                            'OR',
                            style: AppFonts.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.l),

                    // Google Sign-In Button
                    // Google Sign-In Button
                    Obx(() => SecondaryButton(
                          text: 'Continue with Google',
                          icon: Icons
                              .g_mobiledata, // Fallback icon, ideally use assets
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.loginWithGoogle,
                          isFullWidth: true,
                        )),

                    const Spacer(),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: AppFonts.bodyMedium,
                        ),
                        AppTextButton(
                          text: 'Sign Up',
                          onPressed: controller.goToSignup,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
