import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../domain/models/donation_request.dart';

/// Repository managing blood requests in Firestore with demo fallback and reactive stream updates.
class RequestsRepository {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  // In-memory demo requests for offline testing and fast reactivity
  final List<DonationRequest> _demoRequests = List.from(MockSeedData.requests);
  final Set<String> _declinedRequestIds = {};

  final _requestsStreamController = StreamController<List<DonationRequest>>.broadcast();

  RequestsRepository() {
    _emit();
  }

  void _emit() {
    _requestsStreamController.add(List.unmodifiable(_demoRequests));
  }

  /// Real-time stream of all open donation requests
  Stream<List<DonationRequest>> watchOpenRequests() async* {
    yield _demoRequests.where((r) => r.isOpen && !_declinedRequestIds.contains(r.id)).toList();

    if (!_isFirebaseReady) {
      yield* _requestsStreamController.stream.map(
        (list) => list.where((r) => r.isOpen && !_declinedRequestIds.contains(r.id)).toList(),
      );
    } else {
      yield* FirebaseFirestore.instance
          .collection(FirestoreCollections.donationRequests)
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DonationRequest.fromMap(doc.data(), documentId: doc.id))
            .where((r) => !_declinedRequestIds.contains(r.id))
            .toList();
      });
    }
  }

  /// Real-time stream of incoming/received requests for a user (requests not created by them)
  Stream<List<DonationRequest>> watchReceivedRequests(String userId) async* {
    yield _demoRequests.where((r) => r.requesterId != userId && !_declinedRequestIds.contains(r.id)).toList();

    if (!_isFirebaseReady) {
      yield* _requestsStreamController.stream.map(
        (list) => list.where((r) => r.requesterId != userId && !_declinedRequestIds.contains(r.id)).toList(),
      );
    } else {
      yield* FirebaseFirestore.instance
          .collection(FirestoreCollections.donationRequests)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DonationRequest.fromMap(doc.data(), documentId: doc.id))
            .where((r) => r.requesterId != userId && !_declinedRequestIds.contains(r.id))
            .toList();
      });
    }
  }

  /// Watch requests created by a specific user
  Stream<List<DonationRequest>> watchMyRequests(String userId) async* {
    yield _demoRequests.where((r) => r.requesterId == userId).toList();

    if (!_isFirebaseReady) {
      yield* _requestsStreamController.stream.map(
        (list) => list.where((r) => r.requesterId == userId).toList(),
      );
    } else {
      yield* FirebaseFirestore.instance
          .collection(FirestoreCollections.donationRequests)
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DonationRequest.fromMap(doc.data(), documentId: doc.id))
            .toList();
      });
    }
  }

  /// Watch a specific request by ID
  Stream<DonationRequest?> watchRequestById(String requestId) async* {
    yield getRequestByIdSync(requestId);

    if (!_isFirebaseReady) {
      yield* _requestsStreamController.stream.map((list) {
        final idx = list.indexWhere((r) => r.id == requestId);
        return idx != -1 ? list[idx] : null;
      });
    } else {
      yield* FirebaseFirestore.instance
          .collection(FirestoreCollections.donationRequests)
          .doc(requestId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return DonationRequest.fromMap(doc.data()!, documentId: doc.id);
      });
    }
  }

  /// Synchronous retrieval of cached/demo open requests
  List<DonationRequest> getCachedOpenRequests() {
    return _demoRequests.where((r) => r.isOpen).toList();
  }

  /// Find request by id synchronously
  DonationRequest? getRequestByIdSync(String requestId) {
    final idx = _demoRequests.indexWhere((r) => r.id == requestId);
    return idx != -1 ? _demoRequests[idx] : null;
  }

  /// Create a new donation request and simulate Cloud Function push alert to compatible donors
  Future<int> createRequest(DonationRequest request) async {
    _demoRequests.insert(0, request);
    _emit();

    // Simulated Cloud Function: Identify all donors compatible with request.bloodGroup who are active & eligible
    final compatibleGroups = BloodCompatibility.getCompatibleDonorsFor(request.bloodGroup);
    final matchedDonors = MockSeedData.donors.where((d) {
      return d.isActive && d.isEligible && compatibleGroups.contains(d.bloodGroup);
    }).toList();

    if (!_isFirebaseReady) {
      return matchedDonors.length;
    }

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.donationRequests)
          .doc(request.id)
          .set(request.toMap());
    } catch (_) {}

    return matchedDonors.length;
  }

  /// Cancel an open request
  Future<void> cancelRequest(String requestId) async {
    final index = _demoRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _demoRequests[index] = _demoRequests[index].copyWith(status: 'cancelled');
      _emit();
    }

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.donationRequests)
          .doc(requestId)
          .update({'status': 'cancelled'});
    } catch (_) {}
  }

  /// Accept an open blood request
  Future<void> acceptRequest(String requestId, String donorId) async {
    final index = _demoRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final req = _demoRequests[index];
      final updatedAcceptedBy = List<String>.from(req.acceptedBy);
      if (!updatedAcceptedBy.contains(donorId)) {
        updatedAcceptedBy.add(donorId);
      }
      _demoRequests[index] = req.copyWith(
        status: 'accepted',
        acceptedBy: updatedAcceptedBy,
      );
      _emit();
    }

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.donationRequests)
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedBy': FieldValue.arrayUnion([donorId]),
      });
    } catch (_) {}
  }

  /// Decline / dismiss a request for a donor
  Future<void> declineRequest(String requestId, String donorId) async {
    _declinedRequestIds.add(requestId);
    _emit();
  }

  /// Mark request as fulfilled
  Future<void> fulfillRequest(String requestId) async {
    final index = _demoRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _demoRequests[index] = _demoRequests[index].copyWith(status: 'fulfilled');
      _emit();
    }

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.donationRequests)
          .doc(requestId)
          .update({'status': 'fulfilled'});
    } catch (_) {}
  }
}
