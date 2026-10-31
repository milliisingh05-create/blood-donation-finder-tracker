import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../domain/models/user_profile.dart';

/// Repository managing user and donor profile data in Firestore with demo fallback.
class ProfileRepository {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  // In-memory demo profile cache for testing/evaluation
  UserProfile _demoProfile = MockSeedData.donors.first;
  final _controller = StreamController<UserProfile>.broadcast();

  /// Sets the active mock profile for demo mode (e.g. Marcus Chen: O+, Active)
  void setDemoProfile(UserProfile profile) {
    _demoProfile = profile;
    _controller.add(_demoProfile);
  }

  /// Returns synchronous cached/default profile to prevent loading flicker
  UserProfile getCachedProfile(String uid) {
    return _demoProfile.copyWith(uid: uid);
  }

  /// Stream of user profile updates
  Stream<UserProfile> watchProfile(String uid) async* {
    yield _demoProfile.copyWith(uid: uid);

    if (!_isFirebaseReady) {
      yield* _controller.stream.map((p) => p.copyWith(uid: uid));
      return;
    }

    yield* FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return _demoProfile.copyWith(uid: uid);
      }
      return UserProfile.fromMap(snapshot.data()!, documentId: snapshot.id);
    });
  }

  /// Fetches user profile once
  Future<UserProfile> getProfile(String uid) async {
    if (!_isFirebaseReady) {
      return _demoProfile;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!, documentId: doc.id);
      }
      return _demoProfile.copyWith(uid: uid);
    } catch (_) {
      return _demoProfile;
    }
  }

  /// Updates donor availability status ('active' or 'inactive') in real time
  Future<void> updateAvailability(String uid, bool isActive) async {
    final status = isActive ? 'active' : 'inactive';
    _demoProfile = _demoProfile.copyWith(uid: uid, availability: status);
    _controller.add(_demoProfile);

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .update({'availability': status});
    } catch (_) {
      // Fallback update
    }
  }

  /// Updates editable profile information
  Future<void> updateProfile(UserProfile updated) async {
    _demoProfile = updated;
    _controller.add(_demoProfile);

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(updated.uid)
          .set(updated.toMap(), SetOptions(merge: true));
    } catch (_) {
      // Fallback
    }
  }

  void dispose() {
    _controller.close();
  }
}
