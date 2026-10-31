import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'blood_group_chip.dart';

/// Reusable flat card displaying donor information.
/// Implements privacy guard: displays approximate distance instead of exact coordinates.
class DonorCard extends StatelessWidget {
  final String name;
  final String bloodGroup;
  final String distanceAway;
  final bool isActive;
  final String? city;
  final int totalDonations;
  final VoidCallback? onRequestTap;
  final VoidCallback? onCallTap;
  final bool canCall;

  const DonorCard({
    super.key,
    required this.name,
    required this.bloodGroup,
    required this.distanceAway,
    required this.isActive,
    this.city,
    this.totalDonations = 0,
    this.onRequestTap,
    this.onCallTap,
    this.canCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blood group badge
              BloodGroupChip(
                bloodGroup: bloodGroup,
                fontSize: 16,
              ),
              const SizedBox(width: 14),

              // Name and location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Availability status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.inactiveGrey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.success : AppColors.inactiveGrey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isActive ? AppColors.success : AppColors.inactiveGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          city != null ? '$distanceAway • $city' : distanceAway,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Bottom metrics and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalDonations donations recorded',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  if (onCallTap != null)
                    IconButton.filled(
                      onPressed: onCallTap,
                      style: IconButton.styleFrom(
                        backgroundColor: canCall
                            ? const Color(0xFFE8F8F0)
                            : AppColors.lightRedTint,
                        foregroundColor: canCall ? AppColors.success : AppColors.primaryRed,
                      ),
                      icon: Icon(
                        canCall ? Icons.phone_rounded : Icons.phone_locked_rounded,
                        size: 18,
                      ),
                      tooltip: canCall ? 'Call Donor' : 'Locked until request accepted',
                    ),
                  if (onRequestTap != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onRequestTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
