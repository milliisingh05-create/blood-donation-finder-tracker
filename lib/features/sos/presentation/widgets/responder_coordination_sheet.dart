import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../domain/models/sos_responder.dart';
import '../controllers/sos_controller.dart';

/// Modal bottom sheet for live emergency responder coordination, turn-by-turn ETA,
/// direct calling, SMS contact, and milestone status advancement (e.g. Arrived, Draw in Progress).
class ResponderCoordinationSheet extends ConsumerWidget {
  final SosResponder responder;

  const ResponderCoordinationSheet({
    super.key,
    required this.responder,
  });

  Future<void> _makeCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling $phone')),
      );
    }
  }

  Future<void> _sendSms(BuildContext context, String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Messaging $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Responder Identity Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BloodGroupChip(
                    bloodGroup: responder.bloodGroup,
                    fontSize: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          responder.name,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${responder.distanceKm.toStringAsFixed(1)} km away • ${responder.transportMode}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: responder.hasArrived
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.lightRedTint,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: responder.hasArrived ? AppColors.success : AppColors.primaryRed,
                            ),
                          ),
                          child: Text(
                            responder.formattedStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: responder.hasArrived ? AppColors.success : AppColors.primaryRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Contact & Dispatch Actions Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makeCall(context, responder.phone),
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text('Call Donor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _sendSms(context, responder.phone),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primaryRed),
                      label: const Text('Send SMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Status Progression Stepper
              Text('Live Responder Milestone', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _buildStepItem(
                title: 'Dispatched & En Route',
                subtitle: 'ETA: ~${responder.etaMinutes} minutes (${responder.transportMode})',
                isCompleted: true,
                isActive: responder.isEnRoute,
              ),
              _buildStepItem(
                title: 'Arrived at Reception / Blood Bank',
                subtitle: 'Verified donor presence at hospital desk',
                isCompleted: responder.hasArrived || responder.isDrawing || responder.isCompleted,
                isActive: responder.hasArrived,
              ),
              _buildStepItem(
                title: 'Blood Draw in Progress',
                subtitle: 'Medical staff conducting preliminary vitals & phlebotomy',
                isCompleted: responder.isDrawing || responder.isCompleted,
                isActive: responder.isDrawing,
              ),
              _buildStepItem(
                title: 'Emergency Donation Complete',
                subtitle: 'Units safely collected for patient',
                isCompleted: responder.isCompleted,
                isActive: responder.isCompleted,
                isLast: true,
              ),

              const SizedBox(height: 24),

              // Advance Action Button
              if (responder.isEnRoute)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(sosRepositoryProvider).updateResponderStatus(responder.id, 'arrived');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Confirm Donor Arrived at Reception', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                )
              else if (responder.hasArrived)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(sosRepositoryProvider).updateResponderStatus(responder.id, 'drawing');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.water_drop_rounded),
                    label: const Text('Start Blood Draw in Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                )
              else if (responder.isDrawing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(sosRepositoryProvider).updateResponderStatus(responder.id, 'completed');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Mark Donation Completed', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    final Color markerColor = isCompleted
        ? AppColors.success
        : (isActive ? AppColors.primaryRed : AppColors.border);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : (isActive ? AppColors.lightRedTint : AppColors.surface),
                  shape: BoxShape.circle,
                  border: Border.all(color: markerColor, width: 2),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w600,
                      color: isCompleted || isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
