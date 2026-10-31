import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Helper service for handling runtime location and push notification permissions
/// with educational rationale dialogs.
class PermissionService {
  PermissionService._();

  /// Requests location permission with an explanatory dialog
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Location Access',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Blood Donation Finder uses your location to discover nearby compatible donors '
            'and calculate travel distances during medical emergencies. Your exact GPS coordinates '
            'are never displayed publicly to other users.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not Now', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Allow Location'),
            ),
          ],
        ),
      );

      if (proceed != true) return false;
    }

    final result = await Permission.location.request();
    return result.isGranted;
  }

  /// Requests notification permission with an explanatory dialog
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (context.mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Emergency Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Enable push notifications to receive real-time critical SOS broadcasts '
            'when a patient nearby urgently requires your blood group.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enable Alerts'),
            ),
          ],
        ),
      );

      if (proceed != true) return false;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }
}
