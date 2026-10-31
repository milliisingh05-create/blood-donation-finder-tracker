import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../data/donations_repository.dart';
import '../../domain/models/donation_record.dart';

class DonationStats {
  final int totalDonations;
  final int totalUnits;
  final double litersDonated;
  final int estimatedLivesSaved;
  final int totalPoints;
  final int daysUntilEligible;
  final double eligibilityProgress;

  const DonationStats({
    required this.totalDonations,
    required this.totalUnits,
    required this.litersDonated,
    required this.estimatedLivesSaved,
    required this.totalPoints,
    required this.daysUntilEligible,
    required this.eligibilityProgress,
  });

  bool get isEligibleNow => daysUntilEligible <= 0;
}

final donationsRepositoryProvider = Provider<DonationsRepository>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final notifsRepo = ref.watch(notificationsRepositoryProvider);

  final repo = DonationsRepository(
    profileRepository: profileRepo,
    notificationsRepository: notifsRepo,
  );

  ref.onDispose(repo.dispose);
  return repo;
});

final userDonationsStreamProvider = StreamProvider<List<DonationRecord>>((ref) {
  final repo = ref.watch(donationsRepositoryProvider);
  return repo.watchUserDonations('current_user');
});

final donationStatsProvider = Provider<DonationStats>((ref) {
  final donationsAsync = ref.watch(userDonationsStreamProvider);
  final profileAsync = ref.watch(profileControllerProvider);

  final donations = donationsAsync.maybeWhen(
    data: (list) => list,
    orElse: () => <DonationRecord>[],
  );

  final lastDonation = profileAsync.maybeWhen(
    data: (profile) => profile.lastDonationDate,
    orElse: () => donations.isNotEmpty ? donations.first.date : null,
  );

  final totalUnits = donations.fold<int>(0, (sum, item) => sum + item.units);
  final totalPoints = donations.fold<int>(0, (sum, item) => sum + item.pointsEarned);

  return DonationStats(
    totalDonations: donations.length,
    totalUnits: totalUnits,
    litersDonated: totalUnits * 0.45,
    estimatedLivesSaved: totalUnits * 3,
    totalPoints: totalPoints > 0 ? totalPoints : 520,
    daysUntilEligible: DonationsRepository.calculateDaysRemaining(lastDonation),
    eligibilityProgress: DonationsRepository.calculateEligibilityProgress(lastDonation),
  );
});
