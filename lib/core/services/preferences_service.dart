import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing persistent local flags such as onboarding completion status.
class PreferencesService {
  static const String _keyOnboardingCompleted = 'onboarding_completed_v1';
  static bool _inMemoryOnboardingFlag = false;

  /// Check whether the user has already viewed and completed onboarding.
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyOnboardingCompleted) ?? _inMemoryOnboardingFlag;
    } catch (_) {
      return _inMemoryOnboardingFlag;
    }
  }

  /// Mark onboarding as completed so it is not shown again.
  Future<void> setOnboardingCompleted() async {
    _inMemoryOnboardingFlag = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingCompleted, true);
    } catch (_) {
      // In-memory fallback persisted for runtime
    }
  }

  /// Reset onboarding flag (useful for testing or re-visiting tutorial).
  Future<void> resetOnboarding() async {
    _inMemoryOnboardingFlag = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOnboardingCompleted);
    } catch (_) {}
  }
}

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});
