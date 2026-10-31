import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../../core/widgets/digital_donor_card.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/models/donation_record.dart';
import '../controllers/donations_controller.dart';

/// Screen displaying donor's lifelong impact, 90-day medical interval eligibility,
/// interactive milestone badges, digital donor card, and verified donation history timeline.
class DonationsHistoryScreen extends ConsumerStatefulWidget {
  const DonationsHistoryScreen({super.key});

  static const List<Map<String, dynamic>> _milestones = [
    {
      'title': 'First Drop',
      'desc': 'Completed 1st verified donation',
      'icon': Icons.water_drop_rounded,
      'threshold': 1,
      'perks': 'Official Digital Donor Pass & SOS Emergency Alert access',
    },
    {
      'title': 'Life Saver x3',
      'desc': 'Saved up to 9 critical lives',
      'icon': Icons.favorite_rounded,
      'threshold': 3,
      'perks': 'Priority donor matching for urgent hospital requests & Bronze badge',
    },
    {
      'title': 'Golden Heart',
      'desc': '5 heroic community donations',
      'icon': Icons.workspace_premium_rounded,
      'threshold': 5,
      'perks': 'Hospital fast-track coordination & Silver Hero verification',
    },
    {
      'title': 'Universal Hero',
      'desc': 'Top tier community lifesaver',
      'icon': Icons.military_tech_rounded,
      'threshold': 8,
      'perks': 'National Blood Registry VIP status & Lifetime Recognition badge',
    },
  ];

  @override
  ConsumerState<DonationsHistoryScreen> createState() => _DonationsHistoryScreenState();
}

class _DonationsHistoryScreenState extends ConsumerState<DonationsHistoryScreen> {
  bool _showDigitalCard = false;
  String _selectedFilter = 'All Records';

  static const List<String> _filterOptions = [
    'All Records',
    'Whole Blood',
    'Platelets',
    'Plasma',
  ];

  void _showBadgeDetailModal(BuildContext context, Map<String, dynamic> milestone, bool isUnlocked, int totalDonations) {
    final threshold = milestone['threshold'] as int;
    final remaining = threshold - totalDonations;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.lightRedTint : AppColors.border.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? AppColors.primaryRed : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Icon(
                  milestone['icon'] as IconData,
                  size: 32,
                  color: isUnlocked ? AppColors.primaryRed : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                milestone['title'] as String,
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                milestone['desc'] as String,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.success.withValues(alpha: 0.15) : AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUnlocked ? AppColors.success : AppColors.primaryRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUnlocked ? Icons.verified_rounded : Icons.lock_clock_rounded,
                      size: 16,
                      color: isUnlocked ? AppColors.success : AppColors.primaryRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isUnlocked
                          ? 'Unlocked & Verified Active'
                          : '$remaining more donation${remaining > 1 ? "s" : ""} needed ($totalDonations/$threshold)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? AppColors.success : AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Milestone Privilege & Perks',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      milestone['perks'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(donationStatsProvider);
    final donationsAsync = ref.watch(userDonationsStreamProvider);
    final profileAsync = ref.watch(profileControllerProvider);
    final profile = profileAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donation Tracker & History'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutePaths.dashboard);
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutePaths.recordDonation),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Record Donation', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Digital Donor Pass Toggle Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.lightRedTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge_rounded, color: AppColors.primaryRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Digital Donor Pass & QR',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        Text(
                          _showDigitalCard ? 'Tap to hide express QR card' : 'Hospital express check-in QR code',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _showDigitalCard = !_showDigitalCard),
                    icon: Icon(
                      _showDigitalCard ? Icons.keyboard_arrow_up_rounded : Icons.qr_code_2_rounded,
                      size: 16,
                      color: AppColors.primaryRed,
                    ),
                    label: Text(
                      _showDigitalCard ? 'Hide' : 'View Pass',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                    ),
                  ),
                ],
              ),
            ),

            if (_showDigitalCard) ...[
              const SizedBox(height: 14),
              DigitalDonorCard(
                donorName: profile?.name ?? 'Marcus Chen',
                bloodGroup: profile?.bloodGroup ?? 'O+',
                donorId: profile?.uid ?? 'DONOR-7892',
                totalDonations: stats.totalDonations,
                city: profile?.city ?? 'San Francisco, CA',
                isActive: profile?.isActive ?? true,
                memberSince: '2024',
              ),
            ],

            const SizedBox(height: 16),

            // 2. Hero Impact Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeroStat(
                        label: 'Lives Saved',
                        value: '${stats.estimatedLivesSaved}',
                        icon: Icons.favorite_rounded,
                        color: AppColors.primaryRed,
                      ),
                      Container(width: 1, height: 48, color: AppColors.border),
                      _buildHeroStat(
                        label: 'Volume',
                        value: '${stats.litersDonated.toStringAsFixed(1)}L',
                        icon: Icons.water_drop_rounded,
                        color: const Color(0xFF2980B9),
                      ),
                      Container(width: 1, height: 48, color: AppColors.border),
                      _buildHeroStat(
                        label: 'Hero Points',
                        value: '${stats.totalPoints}',
                        icon: Icons.stars_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // 90-Day Medical Interval Countdown
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: stats.eligibilityProgress,
                              strokeWidth: 4,
                              backgroundColor: AppColors.border,
                              color: stats.isEligibleNow ? AppColors.success : AppColors.primaryRed,
                            ),
                            Icon(
                              stats.isEligibleNow ? Icons.check_circle_rounded : Icons.schedule_rounded,
                              size: 18,
                              color: stats.isEligibleNow ? AppColors.success : AppColors.primaryRed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats.isEligibleNow
                                  ? 'Eligible to Donate Blood Today! 🎉'
                                  : 'Next Donation in ${stats.daysUntilEligible} Days',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: stats.isEligibleNow ? AppColors.success : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stats.isEligibleNow
                                  ? '90-day medical interval completed. You can safely save lives.'
                                  : 'Medical recovery interval: ${(stats.eligibilityProgress * 100).toInt()}% completed.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Milestone Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Milestone Achievements', style: AppTextStyles.titleMedium),
                const Text(
                  'Tap to view perks',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 128,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: DonationsHistoryScreen._milestones.map((m) {
                  final isUnlocked = stats.totalDonations >= (m['threshold'] as int);

                  return InkWell(
                    onTap: () => _showBadgeDetailModal(context, m, isUnlocked, stats.totalDonations),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUnlocked ? AppColors.surface : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnlocked ? AppColors.primaryRed : AppColors.border,
                          width: isUnlocked ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isUnlocked ? AppColors.lightRedTint : AppColors.border.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              m['icon'] as IconData,
                              size: 20,
                              color: isUnlocked ? AppColors.primaryRed : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            m['title'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUnlocked ? 'Unlocked' : '${m["threshold"]} donations',
                            style: TextStyle(
                              fontSize: 10,
                              color: isUnlocked ? AppColors.success : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 4. Donation Timeline History & Category Filter Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Donation Timeline', style: AppTextStyles.titleMedium),
                Text(
                  '${stats.totalDonations} Records',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryDark : AppColors.border,
                        width: 1.2,
                      ),
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            donationsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
              ),
              error: (err, _) => Center(
                child: Text('Error loading history: $err', style: AppTextStyles.bodySmall),
              ),
              data: (records) {
                final filtered = _selectedFilter == 'All Records'
                    ? records
                    : records.where((r) => r.donationType == _selectedFilter).toList();

                if (records.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text('No Donations Recorded Yet', style: AppTextStyles.titleSmall),
                          const SizedBox(height: 4),
                          const Text(
                            'Log your first completed donation to start saving lives and unlock badges.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.filter_list_off_rounded, size: 40, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text('No $_selectedFilter records', style: AppTextStyles.titleSmall),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => setState(() => _selectedFilter = 'All Records'),
                            child: const Text('Show All Records', style: TextStyle(color: AppColors.primaryRed)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) => _buildTimelineCard(filtered[idx], idx == filtered.length - 1),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTimelineCard(DonationRecord rec, bool isLast) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BloodGroupChip(bloodGroup: rec.bloodGroup, fontSize: 16),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rec.hospitalName,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateFormat.format(rec.date),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightRedTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rec.donationType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${rec.units} Unit${rec.units > 1 ? "s" : ""} • Up to ${rec.units * 3} lives saved',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Verified Donation',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.lightRedTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${rec.pointsEarned} Pts',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
