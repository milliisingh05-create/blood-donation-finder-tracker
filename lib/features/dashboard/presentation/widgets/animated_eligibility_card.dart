import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Stat card for donor medical eligibility with count-up animation and status badge.
/// Adheres strictly to flat colors and respects reduce-motion accessibility.
class AnimatedEligibilityCard extends StatelessWidget {
  final bool isEligible;
  final int daysUntilEligible;
  final VoidCallback? onTap;

  const AnimatedEligibilityCard({
    super.key,
    required this.isEligible,
    required this.daysUntilEligible,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top Icon and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primaryRed,
                  size: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isEligible ? const Color(0xFFE8F8F0) : const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEligible ? 'READY' : 'WAIT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEligible ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Animated Days / Status text
          if (isEligible)
            Text(
              'Eligible Now',
              style: AppTextStyles.displayMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else if (reduceMotion)
            Text(
              'In $daysUntilEligible days',
              style: AppTextStyles.displayMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.warning,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: daysUntilEligible),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  'In $value days',
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          const SizedBox(height: 2),

          // Indicator Subtitle with 90-day interval
          Text(
            isEligible ? '${AppConfig.eligibilityDays}d interval met' : '${AppConfig.eligibilityDays}d recovery interval',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
