import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _navigationTimer = Timer(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      final authState = ref.read(authControllerProvider);
      if (authState.isAuthenticated) {
        context.go(AppRoutePaths.dashboard);
      } else {
        final prefsService = ref.read(preferencesServiceProvider);
        final completed = await prefsService.hasCompletedOnboarding();
        if (!mounted) return;
        if (completed) {
          context.go(AppRoutePaths.login);
        } else {
          context.go(AppRoutePaths.onboarding);
        }
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LifeLineBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryDark, width: 2),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Blood Donation Finder',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Instant Emergency SOS & Donor Tracker',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
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
