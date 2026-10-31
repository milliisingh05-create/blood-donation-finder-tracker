import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Animated Active/Inactive availability toggle with pulsing indicator.
/// Strictly uses flat colors: Active (#2ECC71), Inactive (#B8AEB0). Zero gradients.
class AnimatedAvailabilityToggle extends StatefulWidget {
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final bool isCompact;

  const AnimatedAvailabilityToggle({
    super.key,
    required this.isActive,
    required this.onToggle,
    this.isCompact = false,
  });

  @override
  State<AnimatedAvailabilityToggle> createState() => _AnimatedAvailabilityToggleState();
}

class _AnimatedAvailabilityToggleState extends State<AnimatedAvailabilityToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedAvailabilityToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Color activeColor = AppColors.success;
    final Color inactiveColor = AppColors.inactiveGrey;
    final Color currentColor = widget.isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: () => widget.onToggle(!widget.isActive),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 14 : 18,
          vertical: widget.isCompact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: widget.isActive ? const Color(0xFFE8F8F0) : const Color(0xFFF2EFEF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: currentColor, width: 1.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing dot indicator
            Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isActive && !reduceMotion)
                  ScaleTransition(
                    scale: _pulseScale,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Text Label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isActive ? 'AVAILABLE (ACTIVE)' : 'INACTIVE (OFFLINE)',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: currentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    fontSize: widget.isCompact ? 12 : 13,
                  ),
                ),
                if (!widget.isCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.isActive ? 'Discoverable on emergency map' : 'Hidden from emergency discovery',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 10),

            // Toggle Icon switch
            Icon(
              widget.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
              color: currentColor,
              size: widget.isCompact ? 28 : 34,
            ),
          ],
        ),
      ),
    );
  }
}
