import 'package:flutter/material.dart';

/// Centralized color palette for Blood Donation Finder & Tracker.
/// Strict rule: FLAT COLORS ONLY. NO GRADIENTS ANYWHERE.
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primaryRed = Color(0xFFFF4B5C);
  static const Color primaryDark = Color(0xFFE63946);
  static const Color lightRedTint = Color(0xFFFFE3E6);
  static const Color background = Color(0xFFFFF6F7);
  static const Color surface = Color(0xFFFFFFFF);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF2B1A1C);
  static const Color textSecondary = Color(0xFF7A5C60);
  static const Color textMuted = Color(0xFFA89496);

  // Status & Availability Colors
  static const Color success = Color(0xFF2ECC71); // Available / Active
  static const Color warning = Color(0xFFFFB020); // Urgent / Attention
  static const Color inactiveGrey = Color(0xFFB8AEB0); // Inactive / Offline
  static const Color error = Color(0xFFE74C3C);

  // Border & Divider Colors (Flat)
  static const Color border = Color(0xFFFFD4D8);
  static const Color divider = Color(0xFFF2DFE2);

  // Chip & Badge Backgrounds
  static const Color chipBackground = Color(0xFFFFE3E6);
  static const Color chipBackgroundActive = Color(0xFFFF4B5C);
}
