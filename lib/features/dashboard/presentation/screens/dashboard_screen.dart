import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../../core/widgets/offline_demo_banner.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/widgets/animated_availability_toggle.dart';
import '../../../requests/presentation/controllers/requests_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../sos/presentation/controllers/sos_controller.dart';
import '../widgets/animated_eligibility_card.dart';
import '../widgets/animated_stat_card.dart';
import '../widgets/staggered_request_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final requestsAsync = ref.watch(openRequestsProvider);
    final unreadNotifsCount = ref.watch(unreadNotificationsCountProvider);
    final activeSosAsync = ref.watch(activeSosBroadcastProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Blood Finder',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: AppColors.primaryDark),
            tooltip: 'Leaderboard',
            onPressed: () => context.push(AppRoutePaths.leaderboard),
          ),
          IconButton(
            icon: Badge.count(
              count: unreadNotifsCount,
              isLabelVisible: unreadNotifsCount > 0,
              backgroundColor: AppColors.primaryRed,
              textColor: Colors.white,
              child: const Icon(Icons.notifications_none_rounded),
            ),
            tooltip: 'Notification Center',
            onPressed: () => context.push(AppRoutePaths.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Donor Profile',
            onPressed: () => context.push(AppRoutePaths.profile),
          ),
        ],
      ),
      body: LifeLineBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Offline Demo Mode / Connectivity Banner
              const OfflineDemoBanner(),

              // 1. Personalized Donor Header & Availability Toggle
              profileAsync.when(
                loading: () => const SizedBox(height: 72),
                error: (_, _) => const SizedBox(),
                data: (profile) {
                  final firstName = profile.name.isNotEmpty
                      ? profile.name.trim().split(' ').first
                      : 'Donor';

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Greeting
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, $firstName 👋',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.city.isNotEmpty ? 'Location: ${profile.city}' : 'Voluntary Donor',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            // Donor Blood Group Badge
                            BloodGroupChip(
                              bloodGroup: profile.bloodGroup,
                              fontSize: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Inline Availability Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Emergency Availability',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            AnimatedAvailabilityToggle(
                              isCompact: true,
                              isActive: profile.isActive,
                              onToggle: (_) =>
                                  ref.read(profileControllerProvider.notifier).toggleAvailability(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 2. High-Urgency Emergency SOS Callout Banner
              activeSosAsync.maybeWhen(
                data: (broadcast) {
                  final isLive = broadcast != null && broadcast.isBroadcasting;
                  return InkWell(
                    onTap: () => context.push(AppRoutePaths.sos),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isLive ? AppColors.primaryDark : AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLive ? AppColors.primaryRed : AppColors.primaryDark,
                          width: isLive ? 2.5 : 1.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLive ? Icons.radar_rounded : Icons.emergency_rounded,
                              color: isLive ? AppColors.primaryDark : AppColors.primaryRed,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isLive)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    Text(
                                      isLive ? 'LIVE SOS IN PROGRESS' : 'EMERGENCY SOS BROADCAST',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isLive
                                      ? '${broadcast.bloodGroup ?? "O-"} needed • ${broadcast.radiusKm.toInt()}km radius • ${broadcast.acceptedCount} responding'
                                      : 'Alert nearby donors in 5km, 10km, 25km radius',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // 3. Animated Donor Stats Grid (4 Count-Up Cards)
              Text(
                'Your Donation Impact',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              profileAsync.when(
                loading: () => const SizedBox(height: 160),
                error: (_, _) => const SizedBox(),
                data: (profile) {
                  // Calculate lives saved: standard rule is 1 whole blood donation rescues up to 3 patients
                  final donationsCount = (profile.points / 65).round().clamp(1, 99);
                  final livesImpacted = donationsCount * 3;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedStatCard(
                              title: 'Total Donations',
                              count: donationsCount,
                              icon: Icons.water_drop_rounded,
                              subtitle: 'Certified',
                              onTap: () => context.push(AppRoutePaths.donations),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AnimatedStatCard(
                              title: 'Lives Impacted',
                              count: livesImpacted,
                              icon: Icons.volunteer_activism_rounded,
                              subtitle: 'Estimated',
                              onTap: () => context.push(AppRoutePaths.donations),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedStatCard(
                              title: 'Donor Points',
                              count: profile.points,
                              suffix: ' pts',
                              icon: Icons.stars_rounded,
                              onTap: () => context.push(AppRoutePaths.leaderboard),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AnimatedEligibilityCard(
                              isEligible: profile.isEligible,
                              daysUntilEligible: profile.daysUntilEligible,
                              onTap: () => context.push(AppRoutePaths.donations),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 4. Quick Actions Grid (Find Donors, SOS, My Donations, Hospitals)
              Text(
                'Quick Actions',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.35,
                children: [
                  _buildQuickAction(
                    context,
                    title: 'Find Donors',
                    subtitle: 'Real-time GPS Map',
                    icon: Icons.map_rounded,
                    route: AppRoutePaths.donorFinder,
                  ),
                  _buildQuickAction(
                    context,
                    title: 'Emergency SOS',
                    subtitle: 'Broadcast Alert',
                    icon: Icons.emergency_rounded,
                    route: AppRoutePaths.sos,
                  ),
                  _buildQuickAction(
                    context,
                    title: 'My Donations',
                    subtitle: 'History & Timeline',
                    icon: Icons.history_edu_rounded,
                    route: AppRoutePaths.donations,
                  ),
                  _buildQuickAction(
                    context,
                    title: 'Hospitals & Banks',
                    subtitle: 'Live Blood Stocks',
                    icon: Icons.local_hospital_rounded,
                    route: AppRoutePaths.hospitals,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 5. Nearby Open Urgent Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Open Requests',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutePaths.requests),
                    child: Text(
                      'View All',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              requestsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                    ),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Unable to load requests: $err', style: AppTextStyles.bodySmall),
                ),
                data: (requests) {
                  if (requests.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No active blood requests in your area right now.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  final displayRequests = requests.take(3).toList();
                  return Column(
                    children: List.generate(
                      displayRequests.length,
                      (i) => StaggeredRequestCard(
                        request: displayRequests[i],
                        index: i,
                        onTap: () => context.push('/requests/${displayRequests[i].id}'),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightRedTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryRed, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
