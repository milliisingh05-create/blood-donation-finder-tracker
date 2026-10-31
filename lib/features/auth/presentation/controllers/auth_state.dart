import '../../domain/models/auth_user.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool onboardingCompleted;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.onboardingCompleted = false,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.authenticated(AuthUser user, {bool onboardingCompleted = true}) =>
      AuthState(status: AuthStatus.authenticated, user: user, onboardingCompleted: onboardingCompleted);

  factory AuthState.unauthenticated({bool onboardingCompleted = false}) =>
      AuthState(status: AuthStatus.unauthenticated, onboardingCompleted: onboardingCompleted);

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get isInitial => status == AuthStatus.initial;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    bool? onboardingCompleted,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
