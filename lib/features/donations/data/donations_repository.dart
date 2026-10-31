import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/domain/models/app_notification.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/models/donation_record.dart';

/// Repository managing donation history, points, badges, and 90-day medical interval tracking.
class DonationsRepository {
  final ProfileRepository? _profileRepository;
  final NotificationsRepository? _notificationsRepository;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  // In-memory donations history for development and offline mode
  final List<DonationRecord> _demoDonations = [
    DonationRecord(
      id: 'rec_001',
      donorId: 'current_user',
      donorName: 'Elena Rostova',
      hospitalId: 'hosp_001',
      hospitalName: 'Metro General Hospital & Trauma Center',
      bloodGroup: 'O-',
      donationType: 'Whole Blood',
      units: 1,
      date: DateTime.now().subtract(const Duration(days: 110)),
      verified: true,
      pointsEarned: 100,
    ),
    DonationRecord(
      id: 'rec_002',
      donorId: 'current_user',
      donorName: 'Elena Rostova',
      hospitalId: 'hosp_002',
      hospitalName: 'Pacific Regional Blood Bank',
      bloodGroup: 'O-',
      donationType: 'Platelets',
      units: 1,
      date: DateTime.now().subtract(const Duration(days: 220)),
      verified: true,
      pointsEarned: 150,
    ),
    DonationRecord(
      id: 'rec_003',
      donorId: 'current_user',
      donorName: 'Elena Rostova',
      hospitalId: 'hosp_003',
      hospitalName: 'Mission Children & University Hospital',
      bloodGroup: 'O-',
      donationType: 'Plasma',
      units: 2,
      date: DateTime.now().subtract(const Duration(days: 340)),
      verified: true,
      pointsEarned: 240,
    ),
  ];

  final _donationsStreamController = StreamController<List<DonationRecord>>.broadcast();

  DonationsRepository({
    ProfileRepository? profileRepository,
    NotificationsRepository? notificationsRepository,
  })  : _profileRepository = profileRepository,
        _notificationsRepository = notificationsRepository {
    _emit();
  }

  void _emit() {
    _donationsStreamController.add(List.unmodifiable(_demoDonations));
  }

  /// Watch user's donation history stream
  Stream<List<DonationRecord>> watchUserDonations(String userId) async* {
    yield List.unmodifiable(_demoDonations);

    if (!_isFirebaseReady) {
      yield* _donationsStreamController.stream;
    } else {
      yield* FirebaseFirestore.instance
          .collection(FirestoreCollections.donations)
          .where('donorId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DonationRecord.fromMap(doc.data(), documentId: doc.id))
            .toList();
      });
    }
  }

  /// Record a new verified donation
  Future<void> recordDonation(DonationRecord record) async {
    _demoDonations.insert(0, record);
    _emit();

    // 1. Update profile points and last donation date
    if (_profileRepository != null) {
      final currentProfile = _profileRepository.getCachedProfile(record.donorId);
      final newPoints = currentProfile.points + record.pointsEarned;
      final newBadges = List<String>.from(currentProfile.badges);

      if (_demoDonations.isNotEmpty && !newBadges.contains('First Drop')) {
        newBadges.add('First Drop');
      }
      if (_demoDonations.length >= 3 && !newBadges.contains('Life Saver x3')) {
          newBadges.add('Life Saver x3');
        }
        if (_demoDonations.length >= 5 && !newBadges.contains('Golden Heart')) {
          newBadges.add('Golden Heart');
        }

        final updatedProfile = currentProfile.copyWith(
          points: newPoints,
          badges: newBadges,
          lastDonationDate: record.date,
        );
        await _profileRepository.updateProfile(updatedProfile);
      }

    // 2. Add celebratory notification
    if (_notificationsRepository != null) {
      await _notificationsRepository.addNotification(
        AppNotification(
          id: 'notif_donation_${DateTime.now().millisecondsSinceEpoch}',
          userId: record.donorId,
          title: '🎉 +${record.pointsEarned} Points Earned!',
          body: 'Thank you for donating ${record.units} unit(s) at ${record.hospitalName}. Up to ${record.units * 3} lives saved!',
          type: 'system',
          read: false,
          createdAt: DateTime.now(),
        ),
      );
    }

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.donations)
          .doc(record.id)
          .set(record.toMap());
    } catch (_) {}
  }

  /// Calculate days remaining until next eligible donation date (90-day medical interval)
  static int calculateDaysRemaining(DateTime? lastDonation) {
    if (lastDonation == null) return 0;
    final daysElapsed = DateTime.now().difference(lastDonation).inDays;
    final remaining = 90 - daysElapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Returns eligibility progress between 0.0 and 1.0
  static double calculateEligibilityProgress(DateTime? lastDonation) {
    if (lastDonation == null) return 1.0;
    final daysElapsed = DateTime.now().difference(lastDonation).inDays;
    if (daysElapsed >= 90) return 1.0;
    return (daysElapsed / 90.0).clamp(0.0, 1.0);
  }

  void dispose() {
    _donationsStreamController.close();
  }
}
