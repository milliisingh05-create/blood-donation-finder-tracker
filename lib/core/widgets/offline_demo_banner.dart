import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../theme/app_colors.dart';

/// Unobtrusive banner indicating whether the app is running in Local Offline Mode
/// or connected to live Cloud Firestore. Zero gradients, flat colors only.
class OfflineDemoBanner extends StatefulWidget {
  final bool compact;

  const OfflineDemoBanner({super.key, this.compact = true});

  @override
  State<OfflineDemoBanner> createState() => _OfflineDemoBannerState();
}

class _OfflineDemoBannerState extends State<OfflineDemoBanner> {
  bool _dismissed = false;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _showInfoDialog() {
    showDialog(
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isFirebaseReady ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
                color: _isFirebaseReady ? AppColors.success : AppColors.primaryRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isFirebaseReady ? 'Cloud Sync Online' : 'Local Offline Mode',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          _isFirebaseReady
              ? 'Firebase Firestore & Auth are connected. Real-time updates and cloud sync are operational.'
              : 'The app is running in Local Offline Mode with in-memory repositories. Core capabilities (Donor Finder, Emergency SOS, Real-time Stock Matrix, 90-Day Tracker, and In-App Notifications) function offline without requiring cloud credentials.',
          style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final isLive = _isFirebaseReady;
    if (!kDebugMode && !isLive) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: _showInfoDialog,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLive ? const Color(0xFFE8F8F0) : AppColors.lightRedTint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isLive ? AppColors.success.withValues(alpha: 0.4) : AppColors.primaryRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLive ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
              size: 16,
              color: isLive ? AppColors.success : AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isLive
                    ? 'Cloud Sync: Online (Firebase connected)'
                    : 'Demo Mode: Offline In-Memory Data (Tap for info)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isLive ? const Color(0xFF1E824C) : AppColors.primaryDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: isLive ? const Color(0xFF1E824C) : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
