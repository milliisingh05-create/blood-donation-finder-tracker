import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../requests/domain/models/donation_request.dart';

/// Staggered animated request card for nearby open requests on the donor dashboard.
/// Animates into view with a smooth slide-and-fade stagger based on its list index.
/// Strictly uses flat colors and respects system accessibility reduce-motion settings.
class StaggeredRequestCard extends StatefulWidget {
  final DonationRequest request;
  final int index;
  final VoidCallback onTap;

  const StaggeredRequestCard({
    super.key,
    required this.request,
    required this.index,
    required this.onTap,
  });

  @override
  State<StaggeredRequestCard> createState() => _StaggeredRequestCardState();
}

class _StaggeredRequestCardState extends State<StaggeredRequestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _staggerTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Stagger start time based on item index
    final staggerDelay = Duration(milliseconds: (widget.index * 120).clamp(0, 800));
    _staggerTimer = Timer(staggerDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final isCrit = widget.request.isCritical;

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCrit ? AppColors.primaryRed : AppColors.border,
          width: isCrit ? 1.6 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BloodGroupChip(
            bloodGroup: widget.request.bloodGroup,
            fontSize: 16,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.request.hospitalName,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCrit ? const Color(0xFFFFE3E6) : const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCrit ? 'CRITICAL' : 'NORMAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCrit ? AppColors.primaryRed : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.request.units} unit(s) • Needed by ${widget.request.requesterName}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a, dd MMM').format(widget.request.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: widget.onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCrit ? AppColors.primaryRed : AppColors.primaryDark,
              foregroundColor: Colors.white,
              minimumSize: const Size(68, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (reduceMotion) {
      return cardContent;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: cardContent,
      ),
    );
  }
}
