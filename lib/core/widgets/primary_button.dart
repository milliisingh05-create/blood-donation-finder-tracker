import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standard full-width or custom-width flat primary button.
/// Strictly uses flat colors: normal #FF4B5C, pressed #E63946, disabled #B8AEB0. Zero gradients.
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double height;
  final double? width;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.height = 54.0,
    this.width,
    this.borderRadius = 16.0,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    if (widget.isOutlined) {
      backgroundColor = _isPressed ? AppColors.lightRedTint : Colors.transparent;
    } else {
      if (!isEnabled) {
        backgroundColor = AppColors.inactiveGrey;
      } else if (_isPressed) {
        backgroundColor = AppColors.primaryDark;
      } else {
        backgroundColor = AppColors.primaryRed;
      }
    }

    final Color textColor = widget.isOutlined
        ? (isEnabled ? AppColors.primaryRed : AppColors.inactiveGrey)
        : Colors.white;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.width ?? double.infinity,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.isOutlined
              ? Border.all(
                  color: isEnabled ? AppColors.primaryRed : AppColors.inactiveGrey,
                  width: 1.8,
                )
              : null,
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: textColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: AppTextStyles.buttonText.copyWith(color: textColor),
                  ),
                ],
              ),
      ),
    );
  }
}
