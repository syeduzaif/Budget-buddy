import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../services/app/settings_service.dart';
import '../../services/firebase/firebase_auth_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/date_utils.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _dotsController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _versionOpacity;

  @override
  void initState() {
    super.initState();

    // Logo: spring scale + rotation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _logoRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Text: fade in + slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    _versionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Loading dots
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Kick off animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });

    // Navigate after minimum 1.5s
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final authService = Get.find<FirebaseAuthService>();
    final user = authService.currentUser;

    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      // User is authenticated — check onboarding
      if (Get.isRegistered<SettingsService>()) {
        final settings = Get.find<SettingsService>();

        // Auto-sync current month
        await settings.setCurrentMonth(AppDateUtils.getCurrentMonthKey());

        if (!settings.onboardingComplete.value) {
          Get.offAllNamed(AppRoutes.onboarding);
        } else {
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        // Settings not yet loaded — auth controller will handle routing
        // Just wait for auth state listener to fire
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1A1525),
                        const Color(0xFF221D2E),
                      ]
                    : [
                        const Color(0xFFFAF8FC),
                        const Color(0xFFF0EBF7),
                      ],
              ),
            ),
          ),

          // Decorative gradient blobs
          Positioned(
            top: -80,
            right: -60,
            child: _GradientBlob(
              size: 250,
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: _GradientBlob(
              size: 300,
              color: const Color(0xFF1ABC9C)
                  .withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: -40,
            child: _GradientBlob(
              size: 180,
              color:
                  AppColors.secondary.withValues(alpha: isDark ? 0.08 : 0.06),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Animated logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotation.value * pi,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App name
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Text(
                        AppConstants.appName,
                        style: AppFonts.h2.copyWith(
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Text(
                      AppConstants.appTagline,
                      style: AppFonts.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading dots
                  AnimatedBuilder(
                    animation: _dotsController,
                    builder: (_, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final delay = i * 0.2;
                        final t =
                            (_dotsController.value - delay).clamp(0.0, 1.0);
                        final scale = 0.5 + 0.5 * sin(t * pi);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.6 + 0.4 * scale),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Version
                  FadeTransition(
                    opacity: _versionOpacity,
                    child: Text(
                      'v${AppConstants.appVersion}',
                      style: AppFonts.caption.copyWith(
                        color: isDark
                            ? AppColors.textMuted.withValues(alpha: 0.6)
                            : AppColors.textMuted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft gradient blob for background decoration.
class _GradientBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GradientBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
