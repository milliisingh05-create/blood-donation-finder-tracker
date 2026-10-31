import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository_interface.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository();
});

class AuthController extends Notifier<AuthState> {
  late final IAuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _checkInitialAuth();
    return AuthState.initial();
  }

  Future<void> _checkInitialAuth() async {
    final user = await _repository.getCurrentUser();
    if (user != null) {
      state = AuthState.authenticated(user, onboardingCompleted: true);
    } else {
      state = AuthState.unauthenticated(onboardingCompleted: false);
    }
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithEmail(email, password);
      state = AuthState.authenticated(user, onboardingCompleted: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String bloodGroup,
    required String city,
    required bool isDonor,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.registerWithEmail(
        name: name,
        email: email,
        password: password,
        phone: phone,
        bloodGroup: bloodGroup,
        city: city,
        isDonor: isDonor,
      );
      state = AuthState.authenticated(user, onboardingCompleted: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signInDemoMode() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInDemoMode();
      // Ensure active mock profile is Marcus Chen (Blood group O+, Active)
      ref.read(profileRepositoryProvider).setDemoProfile(MockSeedData.donors[1]);
      state = AuthState.authenticated(user, onboardingCompleted: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> demoSignIn() async => signInDemoMode();

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _repository.sendPasswordReset(email);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.signInWithPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      );
      state = AuthState.authenticated(user, onboardingCompleted: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = AuthState.unauthenticated(onboardingCompleted: true);
  }

  void setAuthenticated(AuthUser user) {
    state = AuthState.authenticated(user, onboardingCompleted: true);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});
