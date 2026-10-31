import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/models/hospital.dart';
import 'update_stock_modal.dart';

/// Comprehensive Hospital and Blood Bank detail modal bottom sheet.
/// Displays live stock matrix, blood compatibility matches, direct calling,
/// GPS navigation, and express donation pledge.
class HospitalDetailModal extends ConsumerWidget {
  final Hospital hospital;
  final String formattedDistance;

  const HospitalDetailModal({
    super.key,
    required this.hospital,
    required this.formattedDistance,
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

  Future<void> _openDirections(BuildContext context, double lat, double lng, String name) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigating to $name')),
      );
    }
  }

  void _showStaffUpdateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpdateStockModal(hospital: hospital),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final userBloodGroup = profileAsync.asData?.value.bloodGroup ?? 'O+';
    final compatibleRecipients = BloodCompatibility.getCompatibleRecipientsFor(userBloodGroup);

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

              // Hospital Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hospital.isBloodBank
                          ? const Color(0xFF2980B9).withValues(alpha: 0.15)
                          : AppColors.lightRedTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hospital.isBloodBank ? Icons.bloodtype_rounded : Icons.local_hospital_rounded,
                      color: hospital.isBloodBank ? const Color(0xFF2980B9) : AppColors.primaryRed,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              formattedDistance,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                hospital.isBloodBank ? 'Blood Bank' : '24/7 Trauma Hospital',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
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

              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hospital.address,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quick Actions: Call Desk, Directions, Staff Edit
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(context, hospital.phone),
                      icon: const Icon(Icons.phone_rounded, size: 16, color: AppColors.primaryRed),
                      label: const Text('Call Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDirections(context, hospital.latitude, hospital.longitude, hospital.name),
                      icon: const Icon(Icons.directions_rounded, size: 16, color: Color(0xFF2980B9)),
                      label: const Text('Directions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () => _showStaffUpdateModal(context),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    tooltip: 'Staff: Update Inventory',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.lightRedTint,
                      foregroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Compatibility Insight Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userBloodGroup,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Blood Compatibility: $userBloodGroup',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your donation can safely save recipients of: ${compatibleRecipients.join(", ")}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Live Blood Inventory Matrix Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Live Blood Inventory', style: AppTextStyles.titleMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Total: ${hospital.totalStockUnits} units',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 8 Groups Stock Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.15,
                ),
                itemCount: BloodCompatibility.allBloodGroups.length,
                itemBuilder: (ctx, idx) {
                  final group = BloodCompatibility.allBloodGroups[idx];
                  final units = hospital.stockFor(group);
                  final isCritical = units < 3;
                  final isLow = units >= 3 && units <= 5;

                  final Color statusColor = isCritical
                      ? AppColors.primaryRed
                      : isLow
                          ? AppColors.warning
                          : AppColors.success;

                  final String statusText = isCritical
                      ? 'CRITICAL'
                      : isLow
                          ? 'LOW'
                          : 'ADEQUATE';

                  return Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? AppColors.lightRedTint.withValues(alpha: 0.5)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCritical ? AppColors.primaryRed : AppColors.border,
                        width: isCritical ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          group,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isCritical ? AppColors.primaryRed : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$units unit${units != 1 ? "s" : ""}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Action CTA: Record Donation Here
              PrimaryButton(
                text: 'Record Donation at this Center',
                icon: Icons.add_task_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  context.push('${AppRoutePaths.recordDonation}?hospitalId=${hospital.id}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
