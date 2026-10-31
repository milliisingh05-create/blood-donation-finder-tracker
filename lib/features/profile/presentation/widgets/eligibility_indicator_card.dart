import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Card displaying donor eligibility countdown and 90-day medical interval indicator.
/// Zero gradients, flat colors only.
class EligibilityIndicatorCard extends StatelessWidget {
  final DateTime? lastDonationDate;
  final bool isEligible;
  final int daysUntilEligible;

  const EligibilityIndicatorCard({
    super.key,
    required this.lastDonationDate,
    required this.isEligible,
    required this.daysUntilEligible,
  });

  @override
  Widget build(BuildContext context) {
    final int requiredDays = AppConfig.eligibilityDays;
    final int elapsedDays = lastDonationDate != null
        ? DateTime.now().difference(lastDonationDate!).inDays
        : requiredDays;

    final double progress = (elapsedDays / requiredDays).clamp(0.0, 1.0);

    final Color statusColor = isEligible ? AppColors.success : AppColors.warning;
    final Color statusBg = isEligible ? const Color(0xFFE8F8F0) : const Color(0xFFFFF7E6);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEligible ? Icons.verified_user_rounded : Icons.schedule_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Medical Eligibility',
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  isEligible ? 'ELIGIBLE NOW' : 'WAIT PERIOD',
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

          if (isEligible) ...[
            Text(
              'Ready to Save Lives',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lastDonationDate == null
                  ? 'No previous donations recorded. You can donate immediately!'
                  : 'More than $requiredDays days have passed since your last donation on ${DateFormat('dd MMM yyyy').format(lastDonationDate!)}. You are in safe condition to donate.',
              style: AppTextStyles.bodyMedium,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Eligible in $daysUntilEligible days',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($elapsedDays / $requiredDays days)',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Flat Progress Track
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.lightRedTint,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Last donation: ${DateFormat('dd MMM yyyy').format(lastDonationDate!)}. '
              'Standard medical protocols require a 90-day recovery interval between whole blood donations to replenish red cells.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
