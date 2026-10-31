import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Hold-to-confirm emergency SOS trigger button.
/// Prevents accidental taps by requiring a 2-second sustained hold
/// while displaying a progressive circular indicator.
class HoldToConfirmSosButton extends StatefulWidget {
  final VoidCallback onTriggered;
  final Duration holdDuration;

  const HoldToConfirmSosButton({
    super.key,
    required this.onTriggered,
    this.holdDuration = const Duration(seconds: 2),
  });

  @override
  State<HoldToConfirmSosButton> createState() => _HoldToConfirmSosButtonState();
}

class _HoldToConfirmSosButtonState extends State<HoldToConfirmSosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  bool _isTriggered = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_isTriggered) {
          setState(() => _isTriggered = true);
          HapticFeedback.heavyImpact();
          widget.onTriggered();
        }
      });
  }

  @override
  void didUpdateWidget(covariant HoldToConfirmSosButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isTriggered) {
      setState(() {
        _isTriggered = false;
        _holdController.reset();
      });
    }
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isTriggered) return;
    HapticFeedback.mediumImpact();
    _holdController.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isTriggered) return;
    _holdController.reverse();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isTriggered) return;
    _holdController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          final progress = _holdController.value;

          return SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Concentric Pulse Ring (Flat Light Red)
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightRedTint.withValues(
                      alpha: 0.3 + (progress * 0.7),
                    ),
                  ),
                ),

                // 2. Circular Progress Indicator Border
                SizedBox(
                  width: 148,
                  height: 148,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : 0.0,
                    strokeWidth: 5,
                    backgroundColor: AppColors.border,
                    color: AppColors.primaryRed,
                  ),
                ),

                // 3. Central Solid Red Button
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryRed,
                    border: Border.all(
                      color: AppColors.primaryDark,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress > 0
                            ? '${((1.0 - progress) * widget.holdDuration.inSeconds).toStringAsFixed(1)}s'
                            : 'HOLD FOR SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
