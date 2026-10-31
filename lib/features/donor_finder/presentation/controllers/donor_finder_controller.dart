import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../data/donor_finder_repository.dart';

class DonorFinderState {
  final double userLat;
  final double userLng;
  final double selectedRadiusKm;
  final String? selectedBloodGroup;
  final bool activeOnly;
  final List<DiscoveredDonor> donors;
  final DiscoveredDonor? selectedDonor;
  final bool isLoading;

  const DonorFinderState({
    required this.userLat,
    required this.userLng,
    this.selectedRadiusKm = 10.0,
    this.selectedBloodGroup,
    this.activeOnly = true,
    this.donors = const [],
    this.selectedDonor,
    this.isLoading = false,
  });

  DonorFinderState copyWith({
    double? userLat,
    double? userLng,
    double? selectedRadiusKm,
    String? selectedBloodGroup,
    bool clearBloodGroup = false,
    bool? activeOnly,
    List<DiscoveredDonor>? donors,
    DiscoveredDonor? selectedDonor,
    bool clearSelectedDonor = false,
    bool? isLoading,
  }) {
    return DonorFinderState(
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      selectedBloodGroup: clearBloodGroup ? null : (selectedBloodGroup ?? this.selectedBloodGroup),
      activeOnly: activeOnly ?? this.activeOnly,
      donors: donors ?? this.donors,
      selectedDonor: clearSelectedDonor ? null : (selectedDonor ?? this.selectedDonor),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final donorFinderRepositoryProvider = Provider<DonorFinderRepository>((ref) {
  return DonorFinderRepository();
});

class DonorFinderController extends Notifier<DonorFinderState> {
  late final DonorFinderRepository _repository;
  StreamSubscription<List<DiscoveredDonor>>? _donorsSubscription;

  @override
  DonorFinderState build() {
    _repository = ref.read(donorFinderRepositoryProvider);
    ref.onDispose(() => _donorsSubscription?.cancel());

    // Schedule initial donor query and GPS check after build returns state
    Future.microtask(() {
      if (!ref.mounted) return;
      _queryDonors();
      _initGps();
    });

    return const DonorFinderState(
      userLat: LocationService.defaultLatitude,
      userLng: LocationService.defaultLongitude,
      isLoading: false,
    );
  }

  Future<void> _initGps() async {
    final position = await LocationService.determinePosition();
    if (!ref.mounted) return;
    state = state.copyWith(
      userLat: position.latitude,
      userLng: position.longitude,
      isLoading: false,
    );
    _queryDonors();
  }

  void _queryDonors() {
    _donorsSubscription?.cancel();
    _donorsSubscription = _repository
        .watchNearbyDonors(
          userLat: state.userLat,
          userLng: state.userLng,
          radiusKm: state.selectedRadiusKm,
          bloodGroup: state.selectedBloodGroup,
          activeOnly: state.activeOnly,
        )
        .listen((results) {
      if (!ref.mounted) return;
      state = state.copyWith(donors: results);
    });
  }

  void setRadius(double radiusKm) {
    state = state.copyWith(selectedRadiusKm: radiusKm);
    _queryDonors();
  }

  void setBloodGroup(String? group) {
    if (group == null || group.isEmpty) {
      state = state.copyWith(clearBloodGroup: true);
    } else {
      state = state.copyWith(selectedBloodGroup: group);
    }
    _queryDonors();
  }

  void toggleActiveOnly(bool activeOnly) {
    state = state.copyWith(activeOnly: activeOnly);
    _queryDonors();
  }

  void selectDonor(DiscoveredDonor? donor) {
    if (donor == null) {
      state = state.copyWith(clearSelectedDonor: true);
    } else {
      state = state.copyWith(selectedDonor: donor);
    }
  }
}

final donorFinderControllerProvider =
    NotifierProvider<DonorFinderController, DonorFinderState>(() {
  return DonorFinderController();
});
