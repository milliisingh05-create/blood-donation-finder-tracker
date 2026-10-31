import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Single falling blood drop data model.
class _DropData {
  double x; // 0.0 to 1.0 (relative width)
  double y; // 0.0 to 1.0 (relative height)
  final double speed;
  final double radius;
  final double opacity;

  _DropData({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}

/// Active ripple on the ECG line triggered when a blood drop lands.
class _RippleData {
  final double x;
  final double y;
  double progress = 0.0;

  _RippleData({
    required this.x,
    required this.y,
  });
}

/// Animated background featuring falling blood drops, an ECG heartbeat line,
/// and flat landing ripples.
///
/// Strictly uses flat colors (#FF4B5C, #FFE3E6, #FFF6F7). Zero gradients.
/// Optimized for 60fps with RepaintBoundary and respects system reduce-motion settings.
class LifeLineBackground extends StatefulWidget {
  final Widget child;
  final bool showDrops;
  final bool showEcg;
  final double ecgHeightFraction;

  const LifeLineBackground({
    super.key,
    required this.child,
    this.showDrops = true,
    this.showEcg = true,
    this.ecgHeightFraction = 0.82,
  });

  @override
  State<LifeLineBackground> createState() => _LifeLineBackgroundState();
}

class _LifeLineBackgroundState extends State<LifeLineBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_DropData> _drops = [];
  final List<_RippleData> _ripples = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();

    // Initialize 7 staggered blood drops (kept lightweight for 60fps)
    for (int i = 0; i < 7; i++) {
      _drops.add(
        _DropData(
          x: 0.10 + (i * 0.13) + (_random.nextDouble() * 0.05),
          y: _random.nextDouble(), // Staggered initial vertical positions
          speed: 0.002 + (_random.nextDouble() * 0.002),
          radius: 5.0 + (_random.nextDouble() * 4.0),
          opacity: 0.18 + (_random.nextDouble() * 0.16),
        ),
      );
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_updatePhysics);

    _controller.repeat();
  }

  void _updatePhysics() {
    if (!mounted) return;

    final ecgY = widget.ecgHeightFraction;

    // Update drops position
    for (final drop in _drops) {
      drop.y += drop.speed;
      // When drop reaches ECG line level, trigger a ripple
      if (drop.y >= ecgY && drop.y - drop.speed < ecgY) {
        if (_ripples.length < 5) {
          _ripples.add(_RippleData(x: drop.x, y: ecgY));
        }
      }
      // Reset drop when below screen
      if (drop.y > 1.05) {
        drop.y = -0.05;
        drop.x = 0.08 + (_random.nextDouble() * 0.84);
      }
    }

    // Update active ripples
    for (int i = _ripples.length - 1; i >= 0; i--) {
      _ripples[i].progress += 0.035;
      if (_ripples[i].progress >= 1.0) {
        _ripples.removeAt(i);
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePhysics);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    return Stack(
      children: [
        // Flat solid background
        Container(color: AppColors.background),

        // Animated canvas (or static fallback if reduce-motion enabled)
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _LifeLinePainter(
                drops: reduceMotion ? const [] : _drops,
                ripples: reduceMotion ? const [] : _ripples,
                animationProgress: reduceMotion ? 0.0 : _controller.value,
                showDrops: widget.showDrops && !reduceMotion,
                showEcg: widget.showEcg,
                ecgHeightFraction: widget.ecgHeightFraction,
                isStatic: reduceMotion,
              ),
            ),
          ),
        ),

        // Foreground content
        widget.child,
      ],
    );
  }
}

/// Custom painter for solid flat drops, ECG line, and ripples. Zero gradients.
class _LifeLinePainter extends CustomPainter {
  final List<_DropData> drops;
  final List<_RippleData> ripples;
  final double animationProgress;
  final bool showDrops;
  final bool showEcg;
  final double ecgHeightFraction;
  final bool isStatic;

  _LifeLinePainter({
    required this.drops,
    required this.ripples,
    required this.animationProgress,
    required this.showDrops,
    required this.showEcg,
    required this.ecgHeightFraction,
    required this.isStatic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ecgY = size.height * ecgHeightFraction;

    // 1. Draw Falling Drops (Solid flat teardrop shapes)
    if (showDrops) {
      final dropPaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      for (final drop in drops) {
        final cx = drop.x * size.width;
        final cy = drop.y * size.height;
        final r = drop.radius;

        dropPaint.color = AppColors.primaryRed.withValues(alpha: drop.opacity);

        // Teardrop path: circle at bottom, apex at top
        final path = Path();
        path.moveTo(cx, cy - r * 1.6);
        path.quadraticBezierTo(cx + r, cy - r * 0.4, cx + r, cy);
        path.arcToPoint(
          Offset(cx - r, cy),
          radius: Radius.circular(r),
          clockwise: true,
        );
        path.quadraticBezierTo(cx - r, cy - r * 0.4, cx, cy - r * 1.6);
        path.close();

        canvas.drawPath(path, dropPaint);
      }
    }

    // 2. Draw Ripples on ECG Line
    if (ripples.isNotEmpty) {
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..isAntiAlias = true;

      for (final ripple in ripples) {
        final rx = ripple.x * size.width;
        final ry = ecgY;
        final currentRadius = ripple.progress * 28.0;
        final rippleOpacity = (1.0 - ripple.progress).clamp(0.0, 1.0) * 0.45;

        ripplePaint.color = AppColors.primaryRed.withValues(alpha: rippleOpacity);
        canvas.drawCircle(Offset(rx, ry), currentRadius, ripplePaint);
      }
    }

    // 3. Draw ECG Heartbeat Line
    if (showEcg) {
      _paintEcgLine(canvas, size, ecgY);
    }
  }

  void _paintEcgLine(Canvas canvas, Size size, double baselineY) {
    final ecgBasePaint = Paint()
      ..color = AppColors.lightRedTint
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final ecgPulsePaint = Paint()
      ..color = AppColors.primaryRed.withValues(alpha: 0.65)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Draw baseline faint track
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      ecgBasePaint,
    );

    // If static (reduce motion), draw one stationary pulse in the center
    if (isStatic) {
      final path = Path();
      final cx = size.width * 0.5;
      path.moveTo(cx - 60, baselineY);
      _drawSingleEcgPulse(path, cx, baselineY);
      canvas.drawPath(path, ecgPulsePaint);
      return;
    }

    // Dynamic moving ECG life pulse across screen
    final pulseX = (animationProgress * (size.width + 160)) - 80;

    final path = Path();
    path.moveTo(math.max(0, pulseX - 80), baselineY);
    _drawSingleEcgPulse(path, pulseX, baselineY);
    canvas.drawPath(path, ecgPulsePaint);

    // Glowing pulse dot leading the ECG life wave
    final dotPaint = Paint()
      ..color = AppColors.primaryRed
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (pulseX >= 0 && pulseX <= size.width) {
      canvas.drawCircle(Offset(pulseX + 45, baselineY), 3.5, dotPaint);
    }
  }

  void _drawSingleEcgPulse(Path path, double cx, double cy) {
    // P wave (slight bump)
    path.lineTo(cx - 40, cy);
    path.quadraticBezierTo(cx - 30, cy - 6, cx - 20, cy);
    // Flat PR segment
    path.lineTo(cx - 14, cy);
    // Q wave (small downward dip)
    path.lineTo(cx - 8, cy + 8);
    // R wave (sharp vertical peak)
    path.lineTo(cx, cy - 36);
    // S wave (deep downward plunge)
    path.lineTo(cx + 8, cy + 18);
    // Return to baseline
    path.lineTo(cx + 14, cy);
    // ST segment
    path.lineTo(cx + 22, cy);
    // T wave (gentle rounded upward bump)
    path.quadraticBezierTo(cx + 32, cy - 12, cx + 42, cy);
    path.lineTo(cx + 55, cy);
  }

  @override
  bool shouldRepaint(covariant _LifeLinePainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.drops.length != drops.length ||
        oldDelegate.ripples.length != ripples.length;
  }
}
