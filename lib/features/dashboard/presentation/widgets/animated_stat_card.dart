import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Stat card that smoothly animates its numerical counter value from 0 to the target.
/// Respects system reduce-motion settings and strictly adheres to flat colors.
class AnimatedStatCard extends StatelessWidget {
  final String title;
  final int count;
  final String? suffix;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.count,
    this.suffix,
    this.subtitle,
    required this.icon,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryRed, size: 22),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Count-up Animated Value
          if (reduceMotion)
            Text(
              suffix != null ? '$count$suffix' : '$count',
              style: AppTextStyles.displayMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            )
          else
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: count),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  suffix != null ? '$value$suffix' : '$value',
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                );
              },
            ),
          const SizedBox(height: 2),

          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
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
