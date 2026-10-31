import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/app_notification.dart';
import '../../data/push_notification_service.dart';
import '../controllers/notifications_controller.dart';

/// Notification Center screen managing push alerts, emergency notifications, and status updates.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'all'; // 'all', 'unread', 'sos', 'request'

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _onNotificationTap(AppNotification notif) {
    ref.read(notificationsRepositoryProvider).markAsRead(notif.id);

    final reqId = notif.data?['requestId'];
    if (reqId != null) {
      context.push('/requests/$reqId');
    } else if (notif.isSos) {
      context.push(AppRoutePaths.sos);
    }
  }

  Future<void> _simulateIncomingAlert() async {
    final notif = AppNotification(
      id: 'notif_sos_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user',
      title: '🚨 CRITICAL SOS: O- Blood Needed!',
      body: 'Metro General Hospital ICU issued an urgent appeal for 2 units of O- blood.',
      type: 'sos',
      read: false,
      createdAt: DateTime.now(),
      data: {'requestId': 'req_001', 'urgency': 'critical'},
    );

    await ref.read(notificationsRepositoryProvider).addNotification(notif);
    await ref.read(pushNotificationServiceProvider).showLocalNotification(
      title: notif.title,
      body: notif.body,
      payload: '/requests/req_001',
      isEmergency: true,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        content: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Incoming SOS Alert: Critical O- needed at Metro General Hospital',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () => context.push('/requests/req_001'),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutePaths.dashboard);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded),
            tooltip: 'Simulate Incoming Alert',
            onPressed: _simulateIncomingAlert,
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationsRepositoryProvider).markAllAsRead(),
              child: const Text(
                'Mark All Read',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('unread', 'Unread ($unreadCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('sos', 'Emergency SOS'),
                  const SizedBox(width: 8),
                  _buildFilterChip('request', 'Requests'),
                ],
              ),
            ),
          ),

          // Notifications List
          Expanded(
            child: notifsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
              error: (err, _) => Center(
                child: Text('Error loading notifications: $err', style: AppTextStyles.bodySmall),
              ),
              data: (notifications) {
                final filtered = notifications.where((n) {
                  if (_selectedFilter == 'unread') return !n.read;
                  if (_selectedFilter == 'sos') return n.isSos;
                  if (_selectedFilter == 'request') return n.isRequest || n.isAcceptance;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.lightRedTint,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryRed),
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              size: 36,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'unread'
                                ? 'All Caught Up!'
                                : 'No Notifications',
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedFilter == 'unread'
                                ? 'You have read all your notifications.'
                                : 'Emergency broadcasts and request updates will appear here.',
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) => _buildNotificationCard(filtered[idx]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryRed,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryDark : AppColors.border,
      ),
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildNotificationCard(AppNotification notif) {
    final IconData icon;
    final Color iconColor;
    final Color iconBg;

    if (notif.isSos) {
      icon = Icons.warning_rounded;
      iconColor = AppColors.primaryDark;
      iconBg = AppColors.lightRedTint;
    } else if (notif.isAcceptance) {
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
      iconBg = AppColors.success.withValues(alpha: 0.15);
    } else if (notif.isRequest) {
      icon = Icons.water_drop_rounded;
      iconColor = AppColors.primaryRed;
      iconBg = AppColors.lightRedTint;
    } else {
      icon = Icons.notifications_rounded;
      iconColor = AppColors.textSecondary;
      iconBg = AppColors.border.withValues(alpha: 0.4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: notif.read ? AppColors.surface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.read ? AppColors.border : AppColors.primaryRed.withValues(alpha: 0.4),
          width: notif.read ? 1.0 : 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onNotificationTap(notif),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: notif.read ? FontWeight.w600 : FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimeAgo(notif.createdAt),
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: notif.read ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!notif.read)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
