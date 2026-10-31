import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../domain/models/donation_request.dart';
import '../controllers/requests_controller.dart';

/// Tabbed inbox displaying active incoming requests and user-created requests.
class RequestsInboxScreen extends ConsumerStatefulWidget {
  const RequestsInboxScreen({super.key});

  @override
  ConsumerState<RequestsInboxScreen> createState() => _RequestsInboxScreenState();
}

class _RequestsInboxScreenState extends ConsumerState<RequestsInboxScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _criticalOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'fulfilled':
        return AppColors.success;
      case 'accepted':
        return AppColors.primaryRed;
      case 'cancelled':
        return AppColors.textSecondary;
      case 'open':
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final receivedRequestsAsync = ref.watch(receivedRequestsProvider);
    final myRequestsAsync = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Blood Requests'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryRed,
          indicatorWeight: 3,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutePaths.createRequest),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Critical Only'),
                  selected: _criticalOnly,
                  selectedColor: AppColors.lightRedTint,
                  checkmarkColor: AppColors.primaryRed,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _criticalOnly ? AppColors.primaryRed : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: _criticalOnly ? AppColors.primaryRed : AppColors.border,
                  ),
                  onSelected: (val) => setState(() => _criticalOnly = val),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                const Text(
                  'Auto-updated in real time',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Received Requests Tab
                receivedRequestsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryRed),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading requests: $err', style: AppTextStyles.bodySmall),
                  ),
                  data: (requests) {
                    final filtered = _criticalOnly
                        ? requests.where((r) => r.isCritical).toList()
                        : requests;

                    if (filtered.isEmpty) {
                      return _buildEmptyState(
                        title: 'No Received Requests',
                        subtitle: _criticalOnly
                            ? 'No critical requests right now. Toggle the filter to view all.'
                            : 'All current blood needs in your area have been fulfilled!',
                        icon: Icons.check_circle_outline_rounded,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) => _buildRequestCard(filtered[idx]),
                    );
                  },
                ),

                // 2. Sent Requests Tab
                myRequestsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryRed),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading sent requests: $err', style: AppTextStyles.bodySmall),
                  ),
                  data: (myRequests) {
                    final filtered = _criticalOnly
                        ? myRequests.where((r) => r.isCritical).toList()
                        : myRequests;

                    if (filtered.isEmpty) {
                      return _buildEmptyState(
                        title: 'No Requests Sent',
                        subtitle: 'Broadcast a new blood request whenever you or a patient needs immediate units.',
                        icon: Icons.post_add_rounded,
                        actionText: 'Create Blood Request',
                        onAction: () => context.push(AppRoutePaths.createRequest),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) => _buildRequestCard(filtered[idx]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(DonationRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: req.isCritical ? AppColors.primaryRed : AppColors.border,
          width: req.isCritical ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/requests/${req.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BloodGroupChip(
                      bloodGroup: req.bloodGroup,
                      fontSize: 16,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  req.hospitalName,
                                  style: AppTextStyles.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(req.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Patient: ${req.requesterName} • ${req.units} Unit${req.units > 1 ? "s" : ""}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (req.isCritical)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CRITICAL',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor(req.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(req.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryRed),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    String? actionText,
    VoidCallback? onAction,
  }) {
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
              child: Icon(icon, size: 36, color: AppColors.primaryRed),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
