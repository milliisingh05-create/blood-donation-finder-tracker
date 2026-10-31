import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../profile/domain/models/user_profile.dart';

/// Repository managing community donor rankings and points leaderboard.
class LeaderboardRepository {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  /// Watch leaderboard rankings sorted by points descending.
  Stream<List<UserProfile>> watchLeaderboard({String category = 'all'}) async* {
    if (!_isFirebaseReady) {
      // Local development & offline mode: sort mock donors
      List<UserProfile> list = List<UserProfile>.from(MockSeedData.donors);

      if (category == 'universal') {
        list = list.where((d) => d.bloodGroup == 'O-').toList();
      }

      list.sort((a, b) => b.points.compareTo(a.points));
      yield list;
      return;
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .where('isDonor', isEqualTo: true);

    if (category == 'universal') {
      query = query.where('bloodGroup', isEqualTo: 'O-');
    }

    yield* query
        .orderBy('points', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
  }
}
