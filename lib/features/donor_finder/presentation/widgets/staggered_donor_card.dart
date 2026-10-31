import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/donor_card.dart';
import '../../data/donor_finder_repository.dart';

/// Staggered animated wrapper for DonorCard in the donor discovery bottom sheet.
/// Ensures each donor card smoothly slides up and fades in with an index-based cascade.
class StaggeredDonorCard extends StatefulWidget {
  final DiscoveredDonor donor;
  final int index;
  final bool isSelected;
  final bool canCall;
  final VoidCallback onCallTap;
  final VoidCallback onRequestTap;

  const StaggeredDonorCard({
    super.key,
    required this.donor,
    required this.index,
    this.isSelected = false,
    this.canCall = false,
    required this.onCallTap,
    required this.onRequestTap,
  });

  @override
  State<StaggeredDonorCard> createState() => _StaggeredDonorCardState();
}

class _StaggeredDonorCardState extends State<StaggeredDonorCard>
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
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final delay = Duration(milliseconds: (widget.index * 70).clamp(0, 700));
    _staggerTimer = Timer(delay, () {
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

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isSelected ? AppColors.primaryRed : Colors.transparent,
          width: 2,
        ),
      ),
      child: DonorCard(
        name: widget.donor.profile.name,
        bloodGroup: widget.donor.profile.bloodGroup,
        distanceAway: widget.donor.formattedDistance,
        isActive: widget.donor.profile.isActive,
        city: widget.donor.profile.city,
        totalDonations: widget.donor.profile.badges.length + 1,
        canCall: widget.canCall,
        onCallTap: widget.onCallTap,
        onRequestTap: widget.onRequestTap,
      ),
    );

    if (reduceMotion) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: card,
        ),
      ),
    );
  }
}
