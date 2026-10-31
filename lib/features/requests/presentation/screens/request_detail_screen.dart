import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../controllers/requests_controller.dart';

/// Comprehensive request detail screen with secure donor match,
/// privacy gate, and acceptance/fulfillment flows.
class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _isActionInProgress = false;

  Future<void> _acceptRequest(String requestId) async {
    setState(() => _isActionInProgress = true);

    final repo = ref.read(requestsRepositoryProvider);
    await repo.acceptRequest(requestId, 'current_user');

    // Notify requester
    final notifRepo = ref.read(notificationsRepositoryProvider);
    await notifRepo.addNotification(
      AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        title: '✅ Request Accepted!',
        body: 'You agreed to donate blood. Hospital contact details and desk phone are now unlocked below.',
        type: 'acceptance',
        read: false,
        createdAt: DateTime.now(),
        data: {'requestId': requestId},
      ),
    );

    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Thank you! You have accepted this blood request.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _fulfillRequest(String requestId) async {
    setState(() => _isActionInProgress = true);

    final repo = ref.read(requestsRepositoryProvider);
    await repo.fulfillRequest(requestId);

    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Blood request marked as successfully fulfilled!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _declineRequest(String requestId) async {
    setState(() => _isActionInProgress = true);

    final repo = ref.read(requestsRepositoryProvider);
    await repo.declineRequest(requestId, 'current_user');

    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request declined.'),
        backgroundColor: AppColors.textSecondary,
      ),
    );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/requests');
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this blood request? Nearby donors will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Active', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionInProgress = true);
    final repo = ref.read(requestsRepositoryProvider);
    await repo.cancelRequest(requestId);

    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Blood request has been cancelled.'),
        backgroundColor: AppColors.textSecondary,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialing $phoneNumber...')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dialing $phoneNumber...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(singleRequestProvider(widget.requestId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/requests');
            }
          },
        ),
      ),
      body: requestAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
        error: (err, _) => Center(
          child: Text('Error loading request: $err', style: AppTextStyles.bodyMedium),
        ),
        data: (request) {
          if (request == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 60, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text('Request Not Found', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final isRequester = request.requesterId == 'current_user';
          final hasAccepted = request.acceptedBy.contains('current_user') || request.isAccepted;
          final canViewContact = hasAccepted || isRequester;
          final compatibleDonors = BloodCompatibility.getCompatibleDonorsFor(request.bloodGroup);

          Color statusColor;
          switch (request.status.toLowerCase()) {
            case 'fulfilled':
              statusColor = AppColors.success;
              break;
            case 'accepted':
              statusColor = AppColors.primaryRed;
              break;
            case 'cancelled':
              statusColor = AppColors.textSecondary;
              break;
            case 'open':
            default:
              statusColor = AppColors.warning;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Urgency Alert Banner
                if (request.isCritical)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightRedTint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryRed, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: AppColors.primaryRed, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CRITICAL EMERGENCY REQUEST',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Immediate transfusion required at hospital ICU.',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Primary Request Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              BloodGroupChip(
                                bloodGroup: request.bloodGroup,
                                fontSize: 20,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${request.units} Unit${request.units > 1 ? "s" : ""} Needed',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Patient: ${request.requesterName}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              request.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primaryRed),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Can receive from: ${compatibleDonors.join(", ")}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Hospital Location & Medical Center
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_hospital_rounded, size: 20, color: AppColors.primaryRed),
                          const SizedBox(width: 8),
                          Text('Medical Center', style: AppTextStyles.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        request.hospitalName,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coordinate directly with the blood bank unit upon arrival.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Clinical Notes / Details
                if (request.note.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notes_rounded, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Clinical Notes', style: AppTextStyles.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          request.note,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // 5. Privacy Gate & Direct Contact
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: canViewContact ? AppColors.success : AppColors.border,
                      width: canViewContact ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            canViewContact ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                            size: 20,
                            color: canViewContact ? AppColors.success : AppColors.primaryRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            canViewContact
                                ? (isRequester ? 'Requester Contact Details' : 'Direct Contact Unlocked')
                                : 'Privacy Protection Gate',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: canViewContact ? AppColors.success : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (canViewContact) ...[
                        Text(
                          isRequester
                              ? 'Contact number registered for hospital and donor coordination:'
                              : 'You have accepted this request. Contact the patient care team directly:',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _makePhoneCall(request.contactNumber),
                                icon: const Icon(Icons.phone_rounded, size: 18),
                                label: Text(request.contactNumber),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'To protect patients and families from spam, direct phone lines are revealed only after you confirm your willingness to donate.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 6. Action Buttons
                if (request.isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: AppColors.textSecondary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This blood request has been cancelled.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (request.isFulfilled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This blood request was successfully fulfilled! Thank you to our donors.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isRequester)
                  if (request.isOpen)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isActionInProgress ? null : () => _cancelRequest(request.id),
                            icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.primaryRed),
                            label: const Text('Cancel', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primaryRed),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            text: 'Mark as Fulfilled',
                            isLoading: _isActionInProgress,
                            icon: Icons.done_all_rounded,
                            onPressed: () => _fulfillRequest(request.id),
                          ),
                        ),
                      ],
                    )
                  else
                    PrimaryButton(
                      text: 'Mark as Fulfilled',
                      isLoading: _isActionInProgress,
                      icon: Icons.done_all_rounded,
                      onPressed: () => _fulfillRequest(request.id),
                    )
                else
                  // Donor View
                  if (!hasAccepted && request.isOpen)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isActionInProgress ? null : () => _declineRequest(request.id),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Decline', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            text: 'Accept Request',
                            isLoading: _isActionInProgress,
                            icon: Icons.check_circle_outline_rounded,
                            onPressed: () => _acceptRequest(request.id),
                          ),
                        ),
                      ],
                    )
                  else if (hasAccepted)
                    PrimaryButton(
                      text: 'Mark as Fulfilled',
                      isLoading: _isActionInProgress,
                      icon: Icons.done_all_rounded,
                      onPressed: () => _fulfillRequest(request.id),
                    ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
