import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Reusable metric/stat card with flat styling.
/// Displays count value, label, and contextual icon.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
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
