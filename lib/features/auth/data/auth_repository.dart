import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../profile/domain/models/user_profile.dart';
import '../domain/models/auth_user.dart';
import '../domain/repositories/auth_repository_interface.dart';

/// Repository handling authentication via Firebase Auth with graceful offline demo fallback.
class AuthRepository implements IAuthRepository {
  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  /// Retrieves current logged-in user or null
  @override
  Future<AuthUser?> getCurrentUser() async {
    if (!_isFirebaseReady) return null;

    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return AuthUser(
        uid: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sign in with Email and Password
  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    if (!_isFirebaseReady) {
      // Demo fallback when Firebase project is not yet configured
      return AuthUser(
        uid: MockSeedData.donors.first.uid,
        email: email,
        displayName: MockSeedData.donors.first.name,
      );
    }

    try {
      final credential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      return AuthUser(
        uid: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
      );
    } catch (e) {
      if (e is fb.FirebaseAuthException) {
        throw _mapFirebaseAuthError(e.code);
      }
      throw 'An unexpected login error occurred. Please try again.';
    }
  }

  /// Register a new account with profile initialization
  @override
  Future<AuthUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String bloodGroup,
    required String city,
    required bool isDonor,
  }) async {
    if (!_isFirebaseReady) {
      return AuthUser(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: name,
        phoneNumber: phone,
      );
    }

    try {
      final credential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name);

      // Create initial Firestore UserProfile
      final profile = UserProfile(
        uid: user.uid,
        name: name,
        phone: phone,
        email: email,
        bloodGroup: bloodGroup,
        city: city,
        geohash: '9q8yy',
        latitude: 37.7749,
        longitude: -122.4194,
        isDonor: isDonor,
        availability: isDonor ? 'active' : 'inactive',
        points: 50, // Welcome points
        badges: ['First Drop'],
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .set(profile.toMap());

      return AuthUser(
        uid: user.uid,
        email: user.email,
        phoneNumber: phone,
        displayName: name,
      );
    } catch (e) {
      if (e is fb.FirebaseAuthException) {
        throw _mapFirebaseAuthError(e.code);
      }
      throw 'Registration failed. Please check your network and details.';
    }
  }

  /// Sends password reset email
  @override
  Future<void> sendPasswordReset(String email) async {
    if (!_isFirebaseReady) return;

    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      if (e is fb.FirebaseAuthException) {
        throw _mapFirebaseAuthError(e.code);
      }
      throw 'Failed to send reset link. Please verify the email address.';
    }
  }

  /// Demo Mode login: skips Firebase and logs in as mock donor (O+, Active)
  /// Available only in debug builds.
  @override
  Future<AuthUser> signInDemoMode() async {
    if (!kDebugMode) {
      throw 'Demo mode authentication is only permitted in debug builds.';
    }
    final mockDonor = MockSeedData.donors[1]; // Marcus Chen (O+, Active)
    return AuthUser(
      uid: mockDonor.uid,
      email: mockDonor.email,
      displayName: mockDonor.name,
      phoneNumber: mockDonor.phone,
    );
  }

  /// Quick login for local development testing
  Future<AuthUser> demoQuickSignIn() async {
    return signInDemoMode();
  }

  /// Verify phone number and send OTP via SMS
  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(AuthUser user)? onAutoVerified,
  }) async {
    final cleanPhone = phoneNumber.trim();

    if (!_isFirebaseReady) {
      await Future.delayed(const Duration(milliseconds: 600));
      onCodeSent('offline_vid_${cleanPhone.hashCode}', null);
      return;
    }

    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: cleanPhone,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          try {
            final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
            final fbUser = userCredential.user;
            if (fbUser != null) {
              final authUser = AuthUser(
                uid: fbUser.uid,
                email: fbUser.email,
                displayName: fbUser.displayName ?? 'Phone Donor',
                phoneNumber: fbUser.phoneNumber ?? cleanPhone,
              );
              onAutoVerified?.call(authUser);
            }
          } catch (e) {
            onError(e.toString());
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          onError(_mapFirebaseAuthError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError('Unable to initiate phone verification: ${e.toString()}');
    }
  }

  /// Verify OTP code and authenticate user
  @override
  Future<AuthUser> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final cleanPhone = phoneNumber.trim();

    if (!_isFirebaseReady) {
      if (smsCode.trim().length != 6) {
        throw 'Please enter a valid 6-digit verification code.';
      }
      return AuthUser(
        uid: 'phone_donor_${cleanPhone.replaceAll(RegExp(r'\D'), '')}',
        displayName: 'Phone Donor',
        phoneNumber: cleanPhone,
      );
    }

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw 'Failed to authenticate phone credential.';
      }

      final userDoc = await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(fbUser.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(fbUser.uid)
            .set({
          'uid': fbUser.uid,
          'name': 'Phone Donor',
          'phone': cleanPhone,
          'bloodGroup': 'O+',
          'isDonor': true,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return AuthUser(
        uid: fbUser.uid,
        email: fbUser.email,
        displayName: fbUser.displayName ?? 'Phone Donor',
        phoneNumber: fbUser.phoneNumber ?? cleanPhone,
      );
    } catch (e) {
      if (e is fb.FirebaseAuthException) {
        throw _mapFirebaseAuthError(e.code);
      }
      throw 'Phone verification failed: ${e.toString()}';
    }
  }

  /// Signs out current session
  @override
  Future<void> signOut() async {
    if (_isFirebaseReady) {
      await fb.FirebaseAuth.instance.signOut();
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is improperly formatted.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'invalid-phone-number':
        return 'The phone number entered is invalid.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again.';
      case 'session-expired':
        return 'The verification code has expired. Please request a new one.';
      case 'network-request-failed':
        return 'Network connection error. Please verify your connection.';
      default:
        return 'Authentication failed ($code).';
    }
  }
}
