import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/services/location_service.dart';
import '../domain/models/hospital.dart';

/// Hospital item combined with computed distance from user.
class HospitalWithDistance {
  final Hospital hospital;
  final double distanceKm;

  const HospitalWithDistance({
    required this.hospital,
    required this.distanceKm,
  });

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km away';
}

/// Repository managing hospital and blood bank directory and live inventory.
class HospitalsRepository {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  final List<Hospital> _demoHospitals = List.from(MockSeedData.hospitals);
  final _hospitalsStreamController = StreamController<List<Hospital>>.broadcast();

  HospitalsRepository() {
    _emit();
  }

  void _emit() {
    _hospitalsStreamController.add(List.unmodifiable(_demoHospitals));
  }

  /// Watch live hospitals and blood banks stream
  Stream<List<Hospital>> watchHospitals() async* {
    yield List.unmodifiable(_demoHospitals);

    if (!_isFirebaseReady) {
      yield* _hospitalsStreamController.stream;
    } else {
      yield* FirebaseFirestore.instance
          .collection(FirestoreCollections.hospitals)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Hospital.fromMap(doc.data(), documentId: doc.id))
            .toList();
      });
    }
  }

  /// Update stock for a specific hospital and blood group
  Future<void> updateBloodStock({
    required String hospitalId,
    required String bloodGroup,
    required int newUnits,
  }) async {
    final idx = _demoHospitals.indexWhere((h) => h.id == hospitalId);
    if (idx != -1) {
      final currentStock = Map<String, int>.from(_demoHospitals[idx].bloodStock);
      currentStock[bloodGroup.toUpperCase()] = newUnits.clamp(0, 999);

      _demoHospitals[idx] = _demoHospitals[idx].copyWith(
        bloodStock: currentStock,
        updatedAt: DateTime.now(),
      );
      _emit();
    }

    if (!_isFirebaseReady) return;

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.hospitals)
          .doc(hospitalId)
          .update({
        'bloodStock.${bloodGroup.toUpperCase()}': newUnits.clamp(0, 999),
        'updatedAt': Timestamp.now(),
      });
    } catch (_) {}
  }

  /// Compute sorted list with distance from coordinates
  List<HospitalWithDistance> getHospitalsWithDistance({
    required double userLat,
    required double userLng,
    String? query,
    String? type,
    String? bloodGroup,
    bool criticalOnly = false,
  }) {
    final List<HospitalWithDistance> list = [];

    for (final h in _demoHospitals) {
      // 1. Filter by query
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesName = h.name.toLowerCase().contains(q);
        final matchesAddress = h.address.toLowerCase().contains(q);
        if (!matchesName && !matchesAddress) continue;
      }

      // 2. Filter by type (hospital vs blood_bank)
      if (type != null && type != 'all' && h.type != type) {
        continue;
      }

      // 3. Filter by critical shortage (< 3 units for selected blood group or any group)
      if (criticalOnly) {
        if (bloodGroup != null && bloodGroup.isNotEmpty) {
          if (h.stockFor(bloodGroup) >= 3) continue;
        } else {
          final hasAnyCritical = h.bloodStock.values.any((units) => units < 3);
          if (!hasAnyCritical) continue;
        }
      }

      final dist = LocationService.calculateDistanceKm(
        startLatitude: userLat,
        startLongitude: userLng,
        endLatitude: h.latitude,
        endLongitude: h.longitude,
      );

      list.add(HospitalWithDistance(hospital: h, distanceKm: dist));
    }

    // Sort ascending by distance (closest first)
    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
  }

  void dispose() {
    _hospitalsStreamController.close();
  }
}
