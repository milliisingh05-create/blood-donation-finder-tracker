import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../data/hospitals_repository.dart';
import '../../domain/models/hospital.dart';

export '../../data/hospitals_repository.dart' show HospitalWithDistance;

class HospitalsFilterState {
  final String query;
  final String type; // 'all', 'hospital', 'blood_bank'
  final String? bloodGroup;
  final bool criticalOnly;

  const HospitalsFilterState({
    this.query = '',
    this.type = 'all',
    this.bloodGroup,
    this.criticalOnly = false,
  });

  HospitalsFilterState copyWith({
    String? query,
    String? type,
    String? bloodGroup,
    bool clearBloodGroup = false,
    bool? criticalOnly,
  }) {
    return HospitalsFilterState(
      query: query ?? this.query,
      type: type ?? this.type,
      bloodGroup: clearBloodGroup ? null : (bloodGroup ?? this.bloodGroup),
      criticalOnly: criticalOnly ?? this.criticalOnly,
    );
  }
}

class HospitalsFilterNotifier extends Notifier<HospitalsFilterState> {
  @override
  HospitalsFilterState build() => const HospitalsFilterState();

  void setQuery(String query) => state = state.copyWith(query: query);
  void setType(String type) => state = state.copyWith(type: type);
  void setBloodGroup(String? group) {
    if (group == null) {
      state = state.copyWith(clearBloodGroup: true);
    } else {
      state = state.copyWith(bloodGroup: group);
    }
  }
  void setCriticalOnly(bool critical) => state = state.copyWith(criticalOnly: critical);
}

final hospitalsFilterNotifierProvider =
    NotifierProvider<HospitalsFilterNotifier, HospitalsFilterState>(() {
  return HospitalsFilterNotifier();
});

final hospitalsRepositoryProvider = Provider<HospitalsRepository>((ref) {
  final repo = HospitalsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final hospitalsStreamProvider = StreamProvider<List<Hospital>>((ref) {
  final repo = ref.watch(hospitalsRepositoryProvider);
  return repo.watchHospitals();
});

final filteredHospitalsProvider = Provider<List<HospitalWithDistance>>((ref) {
  ref.watch(hospitalsStreamProvider);

  final repo = ref.watch(hospitalsRepositoryProvider);
  final filter = ref.watch(hospitalsFilterNotifierProvider);

  return repo.getHospitalsWithDistance(
    userLat: LocationService.defaultLatitude,
    userLng: LocationService.defaultLongitude,
    query: filter.query,
    type: filter.type,
    bloodGroup: filter.bloodGroup,
    criticalOnly: filter.criticalOnly,
  );
});
