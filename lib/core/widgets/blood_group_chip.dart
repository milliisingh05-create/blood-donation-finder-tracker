import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Reusable blood group chip with flat styling.
/// Supports both selectable toggle mode and static badge mode.
class BloodGroupChip extends StatelessWidget {
  final String bloodGroup;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const BloodGroupChip({
    super.key,
    required this.bloodGroup,
    this.isSelected = false,
    this.onSelected,
    this.fontSize = 15.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = onSelected != null;

    final Color bgColor = isSelected ? AppColors.primaryRed : AppColors.lightRedTint;
    final Color textColor = isSelected ? Colors.white : AppColors.primaryDark;
    final Color borderColor = isSelected ? AppColors.primaryDark : AppColors.border;

    Widget chipContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        bloodGroup,
        style: AppTextStyles.titleSmall.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );

    if (isInteractive) {
      return InkWell(
        onTap: () => onSelected!(!isSelected),
        borderRadius: BorderRadius.circular(14),
        child: chipContent,
      );
    }

    return chipContent;
  }
}
