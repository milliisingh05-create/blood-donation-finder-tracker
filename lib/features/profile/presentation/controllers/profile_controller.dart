import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/data/mock_seed_data.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileController extends Notifier<AsyncValue<UserProfile>> {
  late final ProfileRepository _repository;

  @override
  AsyncValue<UserProfile> build() {
    _repository = ref.read(profileRepositoryProvider);
    final authState = ref.read(authControllerProvider);
    final uid = authState.user?.uid ?? MockSeedData.donors.first.uid;

    final initialProfile = _repository.getCachedProfile(uid);
    state = AsyncValue.data(initialProfile);

    _loadProfile(uid);
    return state;
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final profile = await _repository.getProfile(uid);
      if (state.hasValue && state.value?.uid == uid) {
        final currentAvailability = state.value!.availability;
        state = AsyncValue.data(profile.copyWith(availability: currentAvailability));
      } else {
        state = AsyncValue.data(profile);
      }
    } catch (_) {
      // Keep cached state
    }
  }

  Future<void> toggleAvailability() async {
    final current = state.value;
    if (current == null) return;

    final newActive = !current.isActive;
    final updated = current.copyWith(availability: newActive ? 'active' : 'inactive');

    // Optimistic UI update
    state = AsyncValue.data(updated);

    try {
      await _repository.updateAvailability(current.uid, newActive);
    } catch (_) {
      // Revert if failed
      state = AsyncValue.data(current);
    }
  }

  Future<bool> updateProfile(UserProfile updated) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProfile(updated);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void setRole(String newRole) {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(role: newRole));
    }
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, AsyncValue<UserProfile>>(() {
  return ProfileController();
});
