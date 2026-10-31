import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Instant Emergency SOS',
      'subtitle':
          'Broadcast urgent blood alerts to nearby compatible donors within seconds during trauma and ICU emergencies.',
      'icon': Icons.emergency_rounded,
      'badge': 'EMERGENCY RESPONSE',
    },
    {
      'title': 'Real-Time GPS Discovery',
      'subtitle':
          'Locate active donors and live hospital inventory on an interactive map, filtered by medical blood group compatibility.',
      'icon': Icons.explore_rounded,
      'badge': 'GPS DISCOVERY',
    },
    {
      'title': 'Track Impact & Rewards',
      'subtitle':
          'Maintain your verified donation history, monitor 90-day eligibility intervals, and unlock voluntary lifesaver badges.',
      'icon': Icons.military_tech_rounded,
      'badge': 'DONOR REWARDS',
    },
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await ref.read(preferencesServiceProvider).setOnboardingCompleted();
    ref.read(authControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutePaths.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LifeLineBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Blood Finder',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Skip',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 3-Slide PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Tag Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.lightRedTint,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                slide['badge'] as String,
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Large Icon Hero Illustration Container
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border, width: 2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: AppColors.lightRedTint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    slide['icon'] as IconData,
                                    size: 40,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                          // Title
                          Text(
                            slide['title'] as String,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.displayMedium.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Subtitle
                          Text(
                            slide['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                ),
              ),

              // Page Indicators & Action Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Flat Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? AppColors.primaryRed : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Next / Get Started Button
                    PrimaryButton(
                      text: isLast ? 'Get Started' : 'Next',
                      icon: isLast ? Icons.arrow_forward_rounded : null,
                      onPressed: _onNext,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
