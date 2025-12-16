import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/input_fields.dart';
import 'auth_controller.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final AuthController controller = Get.find<AuthController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      controller.signup(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  AppSpacing.l * 2,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      style: AppFonts.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      'Start your financial journey today!',
                      style: AppFonts.bodyLarge.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Name Field
                    AppInputField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppSpacing.l),

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
                          hint: 'Create a password',
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
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        )),

                    const SizedBox(height: AppSpacing.l),

                    // Confirm Password Field
                    Obx(() => AppInputField(
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          controller: _confirmPasswordController,
                          obscureText: !controller.isPasswordVisible.value,
                          prefixIcon: Icons.lock_outline,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (val != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        )),

                    const SizedBox(height: AppSpacing.xl),

                    // Sign Up Button
                    Obx(() => PrimaryButton(
                          text: 'Sign Up',
                          onPressed: _handleSignup,
                          isLoading: controller.isLoading.value,
                          isFullWidth: true,
                        )),

                    const Spacer(),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: AppFonts.bodyMedium,
                        ),
                        AppTextButton(
                          text: 'Login',
                          onPressed: () => Get.back(),
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
