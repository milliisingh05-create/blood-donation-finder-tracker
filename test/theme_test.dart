import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_donation_finder/core/theme/app_colors.dart';
import 'package:blood_donation_finder/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Design System & AppColors Verification', () {
    test('AppColors strict palette matches requirements', () {
      expect(AppColors.primaryRed, const Color(0xFFFF4B5C));
      expect(AppColors.primaryDark, const Color(0xFFE63946));
      expect(AppColors.lightRedTint, const Color(0xFFFFE3E6));
      expect(AppColors.background, const Color(0xFFFFF6F7));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.textPrimary, const Color(0xFF2B1A1C));
      expect(AppColors.textSecondary, const Color(0xFF7A5C60));
      expect(AppColors.success, const Color(0xFF2ECC71));
      expect(AppColors.warning, const Color(0xFFFFB020));
      expect(AppColors.inactiveGrey, const Color(0xFFB8AEB0));
    });

    test('AppTheme is Light Material 3 with flat background', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.primaryColor, AppColors.primaryRed);
    });
  });
}
