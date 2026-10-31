import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/leaderboard_controller.dart';

/// Community Leaderboard showcasing top voluntary blood donors,
/// points standings, and milestone recognitions.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardStreamProvider);
    final selectedCategory = ref.watch(leaderboardCategoryProvider);
    final myProfile = ref.watch(profileControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donor Leaderboard'),
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
      body: LifeLineBackground(
        child: leaderboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (err, _) => Center(
            child: Text('Error loading leaderboard: $err', style: AppTextStyles.bodyMedium),
          ),
          data: (donors) {
            if (donors.isEmpty) {
              return Center(
                child: Text('No donors found in this category.', style: AppTextStyles.bodyMedium),
              );
            }

            final topDonors = donors.take(3).toList();
            final remainingDonors = donors.skip(3).toList();

            // Find current user's rank
            int myRank = -1;
            final me = myProfile;
            if (me != null) {
              final idx = donors.indexWhere((d) => d.uid == me.uid || d.name == me.name);
              if (idx != -1) myRank = idx + 1;
            }

            return Column(
              children: [
                // Category Filter Pills
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildCategoryChip(
                        ref: ref,
                        label: 'All Donors',
                        categoryKey: 'all',
                        isSelected: selectedCategory == 'all',
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        ref: ref,
                        label: 'Universal Heroes (O-)',
                        categoryKey: 'universal',
                        isSelected: selectedCategory == 'universal',
                      ),
                    ],
                  ),
                ),

                // Main Content: Podium + Scrollable List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // Top 3 Podium Card
                      if (topDonors.isNotEmpty)
                        _buildPodium(topDonors),

                      const SizedBox(height: 20),

                      // Section Title
                      Text(
                        'Community Rankings',
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Ranks 4 and beyond
                      ...remainingDonors.asMap().entries.map((entry) {
                        final rank = entry.key + 4;
                        final donor = entry.value;
                        final isMe = myProfile != null && (donor.uid == myProfile.uid || donor.name == myProfile.name);

                        return _buildDonorRankCard(rank, donor, isMe: isMe);
                      }),
                    ],
                  ),
                ),

                // Sticky Current User Ranking Bar
                if (myProfile != null)
                  _buildMyRankFooter(myProfile, myRank),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required WidgetRef ref,
    required String label,
    required String categoryKey,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(leaderboardCategoryProvider.notifier).setCategory(categoryKey);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<UserProfile> topDonors) {
    final first = topDonors.isNotEmpty ? topDonors[0] : null;
    final second = topDonors.length > 1 ? topDonors[1] : null;
    final third = topDonors.length > 2 ? topDonors[2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB020), size: 24),
              const SizedBox(width: 8),
              Text(
                'Top Life Savers',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 2nd Place
              if (second != null)
                Expanded(child: _buildPodiumColumn(second, 2, const Color(0xFF95A5A6), 110)),
              // 1st Place (Center, Elevated)
              if (first != null)
                Expanded(child: _buildPodiumColumn(first, 1, const Color(0xFFFFB020), 140)),
              // 3rd Place
              if (third != null)
                Expanded(child: _buildPodiumColumn(third, 3, const Color(0xFFD35400), 95)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(UserProfile donor, int rank, Color rankColor, double height) {
    final initials = donor.name.isNotEmpty
        ? donor.name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join()
        : 'D';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with blood badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 28 : 24,
              backgroundColor: AppColors.lightRedTint,
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: rank == 1 ? 16 : 14,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rankColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Name
        Text(
          donor.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),

        // Blood group chip
        BloodGroupChip(
          bloodGroup: donor.bloodGroup,
          fontSize: 11,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        ),
        const SizedBox(height: 6),

        // Points
        Text(
          '${donor.points} pts',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
        ),
        const SizedBox(height: 8),

        // Podium Block
        Container(
          height: height * 0.35,
          decoration: BoxDecoration(
            color: AppColors.lightRedTint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: rankColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: rankColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDonorRankCard(int rank, UserProfile donor, {required bool isMe}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.lightRedTint : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primaryRed : AppColors.border,
          width: isMe ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isMe ? AppColors.primaryRed : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Blood Group
          BloodGroupChip(
            bloodGroup: donor.bloodGroup,
            fontSize: 11,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          ),
          const SizedBox(width: 12),

          // Name and City
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        donor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text(
                  donor.city.isNotEmpty ? donor.city : 'Voluntary Donor',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${donor.points} pts',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
              ),
              Text(
                '${(donor.points / 65).round().clamp(1, 99)} donations',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankFooter(UserProfile myProfile, int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightRedTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stars_rounded, color: AppColors.primaryRed, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rank > 0 ? 'Your Community Rank: #$rank' : 'Your Community Rank: Active',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${myProfile.points} total points earned',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            BloodGroupChip(
              bloodGroup: myProfile.bloodGroup,
              fontSize: 11,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            ),
          ],
        ),
      ),
    );
  }
}
