import '../models/auth_user.dart';

/// Abstract interface for authentication services.
/// Allows swapping between Mock and Firebase implementations seamlessly.
abstract class IAuthRepository {
  /// Returns the current signed in user, or null if unauthenticated.
  Future<AuthUser?> getCurrentUser();

  /// Sign in with email and password.
  Future<AuthUser> signInWithEmail(String email, String password);

  /// Register a new donor account with profile details.
  Future<AuthUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String bloodGroup,
    required String city,
    required bool isDonor,
  });

  /// Quick sign-in as a mock voluntary donor (Blood Group: O+, Status: Active).
  /// Completely bypasses Firebase.
  Future<AuthUser> signInDemoMode();

  /// Sends a password reset email.
  Future<void> sendPasswordReset(String email);

  /// Verify phone number and send OTP via SMS.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(AuthUser user)? onAutoVerified,
  });

  /// Verify OTP code and authenticate user.
  Future<AuthUser> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  });

  /// Signs the current user out.
  Future<void> signOut();
}
