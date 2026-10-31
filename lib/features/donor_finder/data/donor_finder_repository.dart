import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/services/location_service.dart';
import '../../profile/domain/models/user_profile.dart';

/// Donor discovery item containing donor profile and computed distance
class DiscoveredDonor {
  final UserProfile profile;
  final double distanceKm;

  const DiscoveredDonor({
    required this.profile,
    required this.distanceKm,
  });

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km away';
}

/// Repository managing real-time GPS donor discovery queries
class DonorFinderRepository {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  /// Stream of nearby donors filtered by radius, blood group, and availability
  Stream<List<DiscoveredDonor>> watchNearbyDonors({
    required double userLat,
    required double userLng,
    required double radiusKm,
    String? bloodGroup,
    bool activeOnly = true,
  }) {
    if (!_isFirebaseReady) {
      return Stream.value(_filterDonorsList(
        MockSeedData.donors,
        userLat: userLat,
        userLng: userLng,
        radiusKm: radiusKm,
        bloodGroup: bloodGroup,
        activeOnly: activeOnly,
      ));
    }

    Query query = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .where('isDonor', isEqualTo: true);

    if (activeOnly) {
      query = query.where('availability', isEqualTo: 'active');
    }

    if (bloodGroup != null && bloodGroup.isNotEmpty) {
      query = query.where('bloodGroup', isEqualTo: bloodGroup);
    }

    return query.snapshots().map((snapshot) {
      final donors = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>, documentId: doc.id))
          .toList();

      return _filterDonorsList(
        donors.isNotEmpty ? donors : MockSeedData.donors,
        userLat: userLat,
        userLng: userLng,
        radiusKm: radiusKm,
        bloodGroup: bloodGroup,
        activeOnly: activeOnly,
      );
    });
  }

  List<DiscoveredDonor> _filterDonorsList(
    List<UserProfile> source, {
    required double userLat,
    required double userLng,
    required double radiusKm,
    String? bloodGroup,
    required bool activeOnly,
  }) {
    final List<DiscoveredDonor> results = [];

    for (final donor in source) {
      if (activeOnly && !donor.isActive) continue;
      if (bloodGroup != null && bloodGroup.isNotEmpty && donor.bloodGroup != bloodGroup) {
        continue;
      }

      final dist = LocationService.calculateDistanceKm(
        startLatitude: userLat,
        startLongitude: userLng,
        endLatitude: donor.latitude,
        endLongitude: donor.longitude,
      );

      if (dist <= radiusKm) {
        results.add(DiscoveredDonor(profile: donor, distanceKm: dist));
      }
    }

    // Sort ascending by distance (closest donors first)
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }
}
