import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../../core/widgets/digital_donor_card.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/animated_availability_toggle.dart';
import '../widgets/eligibility_indicator_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openDonorCardModal(BuildContext context, dynamic profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              DigitalDonorCard(
                donorName: profile.name,
                bloodGroup: profile.bloodGroup,
                donorId: profile.uid,
                totalDonations: profile.badges.length + 1,
                city: profile.city,
                isActive: profile.isActive,
                memberSince: '2024',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donor Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryRed),
            tooltip: 'Digital Donor Pass',
            onPressed: () {
              final profile = profileState.asData?.value;
              if (profile != null) {
                _openDonorCardModal(context, profile);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push(AppRoutePaths.editProfile),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutePaths.login);
              }
            },
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Error loading profile: $err', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
        data: (profile) {
          final initials = profile.name.isNotEmpty
              ? profile.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
              : 'D';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Identity Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // Avatar with initials
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryDark, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            initials.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Name, email, city
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: AppTextStyles.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.email,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(profile.city, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Blood Group Badge
                      BloodGroupChip(
                        bloodGroup: profile.bloodGroup,
                        fontSize: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Digital Donor Pass Quick Access Banner
                InkWell(
                  onTap: () => _openDonorCardModal(context, profile),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.35), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.lightRedTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Digital Donor Pass & QR',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              Text(
                                'Express contactless hospital check-in',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.primaryRed),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Real-Time Animated Availability Toggle
                Center(
                  child: AnimatedAvailabilityToggle(
                    isActive: profile.isActive,
                    onToggle: (_) => ref.read(profileControllerProvider.notifier).toggleAvailability(),
                  ),
                ),
                const SizedBox(height: 24),

                // 90-Day Medical Eligibility Status Card
                EligibilityIndicatorCard(
                  lastDonationDate: profile.lastDonationDate,
                  isEligible: profile.isEligible,
                  daysUntilEligible: profile.daysUntilEligible,
                ),
                const SizedBox(height: 24),

                // Donor Impact Metrics
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Points Earned',
                        value: '${profile.points}',
                        icon: Icons.stars_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Badges',
                        value: '${profile.badges.length}',
                        icon: Icons.military_tech_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Weight',
                        value: profile.weight != null ? '${profile.weight!.toInt()} kg' : '--',
                        icon: Icons.monitor_weight_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Voluntary Badges Showcase
                Text(
                  'Community Badges',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (profile.badges.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('Complete donations to unlock community hero badges!'),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: profile.badges.map((badge) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryRed, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              badge,
                              style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }
}
