import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Concentric radar animation visualizing expanding broadcast radius (5km -> 10km -> 25km).
/// Flat colors only, zero gradients.
class ExpandingRadarVisualizer extends StatefulWidget {
  final double currentRadiusKm;
  final int notifiedCount;
  final int acceptedCount;

  const ExpandingRadarVisualizer({
    super.key,
    required this.currentRadiusKm,
    required this.notifiedCount,
    required this.acceptedCount,
  });

  @override
  State<ExpandingRadarVisualizer> createState() => _ExpandingRadarVisualizerState();
}

class _ExpandingRadarVisualizerState extends State<ExpandingRadarVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Concentric boundary rings (25km, 10km, 5km)
            _buildStaticRing(210, '25 km', isActive: widget.currentRadiusKm >= 25.0),
            _buildStaticRing(150, '10 km', isActive: widget.currentRadiusKm >= 10.0),
            _buildStaticRing(95, '5 km', isActive: widget.currentRadiusKm >= 5.0),

            // Animated expanding radar wave
            if (!reduceMotion)
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final progress = _waveController.value;
                  final maxDiameter = widget.currentRadiusKm >= 25.0
                      ? 210.0
                      : widget.currentRadiusKm >= 10.0
                          ? 150.0
                          : 95.0;
                  final currentDiameter = 40.0 + (progress * (maxDiameter - 40.0));

                  return Container(
                    width: currentDiameter,
                    height: currentDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryRed.withValues(alpha: (1.0 - progress) * 0.25),
                      border: Border.all(
                        color: AppColors.primaryRed.withValues(alpha: (1.0 - progress) * 0.7),
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),

            // Center Hospital Pin
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 22),
            ),

            // Simulated Donor Pins inside the reached radius
            ..._buildSimulatedDonorPins(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRing(double diameter, String label, {required bool isActive}) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primaryRed : AppColors.border,
          width: isActive ? 1.8 : 1.0,
        ),
        color: isActive ? AppColors.lightRedTint.withValues(alpha: 0.15) : Colors.transparent,
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.primaryRed : AppColors.textSecondary,
        ),
      ),
    );
  }

  List<Widget> _buildSimulatedDonorPins() {
    // 4 sample radial donor dots at distinct angles
    final angles = [0.8, 2.2, 3.7, 5.1];
    final distances = [35.0, 60.0, 85.0, 70.0];

    final List<Widget> pins = [];

    for (int i = 0; i < angles.length; i++) {
      final rad = distances[i];
      // Only show pins that fall within the current radius
      if (rad <= (widget.currentRadiusKm >= 25 ? 100 : widget.currentRadiusKm >= 10 ? 70 : 45)) {
        final x = math.cos(angles[i]) * rad;
        final y = math.sin(angles[i]) * rad;

        pins.add(
          Transform.translate(
            offset: Offset(x, y),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: i < widget.acceptedCount ? AppColors.success : AppColors.primaryRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        );
      }
    }

    return pins;
  }
}
