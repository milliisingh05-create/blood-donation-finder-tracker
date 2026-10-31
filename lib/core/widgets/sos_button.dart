import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// High-visibility Emergency SOS button with optional pulsing micro-animation.
/// Uses flat colors only. Respects system reduce-motion settings.
class SosButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final bool isCompact;

  const SosButton({
    super.key,
    required this.onTap,
    this.label = 'EMERGENCY SOS',
    this.isCompact = false,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget buttonContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 16 : 24,
        vertical: widget.isCompact ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDark, width: 2.0),
      ),
      child: Row(
        mainAxisSize: widget.isCompact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: AppColors.primaryRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.label,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: buttonContent,
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        );
      },
      child: buttonContent,
    );
  }
}
