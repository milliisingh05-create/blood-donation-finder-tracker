import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../../core/widgets/primary_button.dart';

/// Full-screen explanation and grant screen for GPS Location and Push Notification permissions.
/// Follows strict flat design (zero gradients).
class PermissionExplanationScreen extends StatefulWidget {
  const PermissionExplanationScreen({super.key});

  @override
  State<PermissionExplanationScreen> createState() => _PermissionExplanationScreenState();
}

class _PermissionExplanationScreenState extends State<PermissionExplanationScreen> {
  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatuses();
  }

  Future<void> _checkCurrentStatuses() async {
    final locStatus = await Permission.location.status;
    final notifStatus = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _locationGranted = locStatus.isGranted;
      _notificationGranted = notifStatus.isGranted;
    });
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    if (!mounted) return;
    setState(() => _locationGranted = status.isGranted);
  }

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _notificationGranted = status.isGranted);
  }

  Future<void> _requestAllAndProceed() async {
    setState(() => _isRequesting = true);
    if (!_locationGranted) {
      final loc = await Permission.location.request();
      _locationGranted = loc.isGranted;
    }
    if (!_notificationGranted) {
      final notif = await Permission.notification.request();
      _notificationGranted = notif.isGranted;
    }
    if (!mounted) return;
    setState(() => _isRequesting = false);
    context.go(AppRoutePaths.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _locationGranted && _notificationGranted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LifeLineBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Top Shield Badge
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.lightRedTint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryRed, width: 2),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 36,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Rationale
                Text(
                  'Essential Permissions',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'To connect you with compatible donors and receive emergency broadcasts when seconds count, please allow the following:',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),

                // 1. Location Card
                _buildPermissionCard(
                  icon: Icons.location_on_rounded,
                  title: 'GPS Location Access',
                  subtitle:
                      'Find nearby compatible donors and calculate transit distances. Exact GPS coordinates are never made public.',
                  isGranted: _locationGranted,
                  onTap: _requestLocation,
                ),
                const SizedBox(height: 14),

                // 2. Notification Card
                _buildPermissionCard(
                  icon: Icons.notifications_active_rounded,
                  title: 'Emergency Push Alerts',
                  subtitle:
                      'Immediate alerts for urgent local blood requests, SOS broadcasts, and donor acceptance confirmations.',
                  isGranted: _notificationGranted,
                  onTap: _requestNotification,
                ),

                const SizedBox(height: 28),

                // Primary CTA
                PrimaryButton(
                  text: allGranted ? 'Continue to Dashboard' : 'Grant Permissions & Continue',
                  isLoading: _isRequesting,
                  icon: allGranted ? Icons.check_circle_rounded : Icons.lock_open_rounded,
                  onPressed: _requestAllAndProceed,
                ),
                const SizedBox(height: 12),

                // Skip / Later
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutePaths.dashboard),
                    child: Text(
                      'Maybe Later',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted ? AppColors.success : AppColors.border,
          width: isGranted ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted ? const Color(0xFFE8F8F0) : AppColors.lightRedTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isGranted ? AppColors.success : AppColors.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isGranted)
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
