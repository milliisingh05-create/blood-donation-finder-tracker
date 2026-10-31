import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../domain/models/sos_broadcast.dart';
import '../domain/models/sos_responder.dart';

/// Repository managing real-time emergency SOS broadcasts with expanding geofence.
class SosRepository {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  SosBroadcast? _currentBroadcast;
  Timer? _expansionTimer;
  final _broadcastStreamController = StreamController<SosBroadcast?>.broadcast();

  SosRepository() {
    _emit();
  }

  void _emit() {
    _broadcastStreamController.add(_currentBroadcast);
  }

  /// Watch the currently active SOS broadcast
  Stream<SosBroadcast?> watchActiveBroadcast() async* {
    yield _currentBroadcast;
    yield* _broadcastStreamController.stream;
  }

  String _currentTimestamp() => DateFormat('HH:mm:ss').format(DateTime.now());

  /// Start a new emergency broadcast
  Future<SosBroadcast> startBroadcast({
    required String bloodGroup,
    required String hospitalName,
    required String contactNumber,
    double initialRadiusKm = 5.0,
  }) async {
    _expansionTimer?.cancel();

    final compatibleGroups = BloodCompatibility.getCompatibleDonorsFor(bloodGroup);
    final initialDonors = MockSeedData.donors.where((d) {
      return d.isActive && compatibleGroups.contains(d.bloodGroup);
    }).toList();

    final initialLogs = [
      '${_currentTimestamp()} - Emergency SOS broadcast initiated for $bloodGroup at $hospitalName (5 km radius).',
      '${_currentTimestamp()} - Dispatched high-priority push alerts to ${initialDonors.length} active donors.',
    ];

    _currentBroadcast = SosBroadcast(
      id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
      requestId: 'req_emergency_${DateTime.now().millisecondsSinceEpoch}',
      radiusKm: initialRadiusKm,
      createdAt: DateTime.now(),
      status: 'broadcasting',
      notifiedCount: initialDonors.length,
      acceptedCount: 0,
      bloodGroup: bloodGroup,
      hospitalName: hospitalName,
      responders: const [],
      timelineLogs: initialLogs,
    );

    _emit();

    if (_isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection(FirestoreCollections.sosBroadcasts)
            .doc(_currentBroadcast!.id)
            .set(_currentBroadcast!.toMap());
      } catch (_) {}
    }

    // Expanding radius simulation: 5km -> 10km -> 25km every 6 seconds
    _startExpandingGeofence();

    return _currentBroadcast!;
  }

  void _startExpandingGeofence() {
    _expansionTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_currentBroadcast == null || !_currentBroadcast!.isBroadcasting) {
        timer.cancel();
        return;
      }

      double nextRadius;
      int extraNotified;
      int extraAccepted;
      final currentResponders = List<SosResponder>.from(_currentBroadcast!.responders);
      final currentLogs = List<String>.from(_currentBroadcast!.timelineLogs);

      if (_currentBroadcast!.radiusKm < 10.0) {
        nextRadius = 10.0;
        extraNotified = 5;
        extraAccepted = 1;

        final newResponder = SosResponder(
          id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
          name: 'David Kim',
          phone: '+1 415-555-0104',
          bloodGroup: _currentBroadcast!.bloodGroup ?? 'O-',
          distanceKm: 2.3,
          etaMinutes: 10,
          status: 'en_route',
          transportMode: 'Vehicle',
          respondedAt: DateTime.now(),
        );
        currentResponders.add(newResponder);
        currentLogs.add('${_currentTimestamp()} - Radius auto-expanded to 10 km. David Kim accepted dispatch (ETA: 10 mins).');
      } else if (_currentBroadcast!.radiusKm < 25.0) {
        nextRadius = 25.0;
        extraNotified = 9;
        extraAccepted = 1;

        final newResponder = SosResponder(
          id: 'resp_${DateTime.now().millisecondsSinceEpoch + 1}',
          name: 'Sofia Rodriguez',
          phone: '+1 415-555-0105',
          bloodGroup: _currentBroadcast!.bloodGroup ?? 'O-',
          distanceKm: 5.1,
          etaMinutes: 16,
          status: 'en_route',
          transportMode: 'Transit',
          respondedAt: DateTime.now(),
        );
        currentResponders.add(newResponder);
        currentLogs.add('${_currentTimestamp()} - Radius auto-expanded to 25 km. Sofia Rodriguez accepted dispatch (ETA: 16 mins).');
      } else {
        timer.cancel();
        return;
      }

      _currentBroadcast = _currentBroadcast!.copyWith(
        radiusKm: nextRadius,
        notifiedCount: _currentBroadcast!.notifiedCount + extraNotified,
        acceptedCount: _currentBroadcast!.acceptedCount + extraAccepted,
        responders: currentResponders,
        timelineLogs: currentLogs,
      );

      _emit();
    });
  }

  /// Manually add responding donor
  void simulateDonorAcceptance() {
    if (_currentBroadcast != null && _currentBroadcast!.isBroadcasting) {
      final currentResponders = List<SosResponder>.from(_currentBroadcast!.responders);
      final currentLogs = List<String>.from(_currentBroadcast!.timelineLogs);

      final names = ['Marcus Chen', 'Aisha Patel', 'Chloe Bennett', 'Jordan Taylor', 'Elena Rostova'];
      final nameIdx = currentResponders.length % names.length;
      final donorName = names[nameIdx];
      final eta = 6 + (currentResponders.length * 4);
      final dist = 1.2 + (currentResponders.length * 1.5);

      final newResponder = SosResponder(
        id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
        name: donorName,
        phone: '+1 415-555-01${20 + currentResponders.length}',
        bloodGroup: _currentBroadcast!.bloodGroup ?? 'O-',
        distanceKm: dist,
        etaMinutes: eta,
        status: 'en_route',
        transportMode: currentResponders.length.isEven ? 'Vehicle' : 'Transit',
        respondedAt: DateTime.now(),
      );

      currentResponders.add(newResponder);
      currentLogs.add('${_currentTimestamp()} - $donorName confirmed emergency response (ETA: $eta mins).');

      _currentBroadcast = _currentBroadcast!.copyWith(
        acceptedCount: _currentBroadcast!.acceptedCount + 1,
        responders: currentResponders,
        timelineLogs: currentLogs,
      );
      _emit();
    }
  }

  /// Update responder status (e.g. 'arrived', 'drawing', 'completed')
  void updateResponderStatus(String responderId, String newStatus) {
    if (_currentBroadcast == null) return;

    final currentResponders = List<SosResponder>.from(_currentBroadcast!.responders);
    final idx = currentResponders.indexWhere((r) => r.id == responderId);
    if (idx != -1) {
      final updated = currentResponders[idx].copyWith(status: newStatus);
      currentResponders[idx] = updated;

      final currentLogs = List<String>.from(_currentBroadcast!.timelineLogs);
      currentLogs.add('${_currentTimestamp()} - ${updated.name}: ${updated.formattedStatus}.');

      _currentBroadcast = _currentBroadcast!.copyWith(
        responders: currentResponders,
        timelineLogs: currentLogs,
      );
      _emit();
    }
  }

  /// Resolve the emergency broadcast once blood units are secured
  Future<void> resolveBroadcast(String id) async {
    _expansionTimer?.cancel();
    if (_currentBroadcast?.id == id) {
      final currentLogs = List<String>.from(_currentBroadcast!.timelineLogs);
      currentLogs.add('${_currentTimestamp()} - Emergency broadcast resolved. Sufficient units secured.');

      _currentBroadcast = _currentBroadcast!.copyWith(
        status: 'resolved',
        timelineLogs: currentLogs,
      );
      _emit();
    }

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.sosBroadcasts)
          .doc(id)
          .update({'status': 'resolved'});
    } catch (_) {}
  }

  /// Cancel broadcast with optional reason
  Future<void> cancelBroadcast(String id, {String? reason}) async {
    _expansionTimer?.cancel();
    if (_currentBroadcast?.id == id) {
      final currentLogs = List<String>.from(_currentBroadcast!.timelineLogs);
      currentLogs.add('${_currentTimestamp()} - Emergency broadcast cancelled (${reason ?? "User cancelled"}).');

      _currentBroadcast = _currentBroadcast!.copyWith(
        status: 'cancelled',
        timelineLogs: currentLogs,
      );
      _emit();
    }

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.sosBroadcasts)
          .doc(id)
          .update({'status': 'cancelled', 'reason': reason ?? 'User cancelled'});
    } catch (_) {}
  }

  void dispose() {
    _expansionTimer?.cancel();
    _broadcastStreamController.close();
  }
}
