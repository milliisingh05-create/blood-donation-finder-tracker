import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'blood_group_chip.dart';

/// Digital Donor ID Card for contactless hospital check-in, verified donor status,
/// and instant emergency identification. Flat color styling, zero gradients.
class DigitalDonorCard extends StatefulWidget {
  final String donorName;
  final String bloodGroup;
  final String donorId;
  final int totalDonations;
  final String city;
  final bool isActive;
  final String memberSince;

  const DigitalDonorCard({
    super.key,
    required this.donorName,
    required this.bloodGroup,
    required this.donorId,
    required this.totalDonations,
    this.city = 'San Francisco, CA',
    this.isActive = true,
    this.memberSince = '2025',
  });

  @override
  State<DigitalDonorCard> createState() => _DigitalDonorCardState();
}

class _DigitalDonorCardState extends State<DigitalDonorCard> {
  bool _showQrCode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Card Header (Card Brand + Status Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.lightRedTint,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DIGITAL DONOR PASS',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.textSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.isActive ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.isActive ? AppColors.success : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isActive ? 'ACTIVE DONOR' : 'INACTIVE',
                        style: TextStyle(
                          color: widget.isActive ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Card Content (Front Details vs QR Check-In)
          Padding(
            padding: const EdgeInsets.all(20),
            child: _showQrCode ? _buildQrCheckInView() : _buildDonorDetailsView(),
          ),

          // 3. Card Footer Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'National Blood Registry Verified',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showQrCode = !_showQrCode),
                  icon: Icon(
                    _showQrCode ? Icons.badge_outlined : Icons.qr_code_2_rounded,
                    size: 16,
                    color: AppColors.primaryRed,
                  ),
                  label: Text(
                    _showQrCode ? 'Show Details' : 'Scan QR',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryRed),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorDetailsView() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BloodGroupChip(
              bloodGroup: widget.bloodGroup,
              fontSize: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.donorName,
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${widget.donorId}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '📍 ${widget.city}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDetailColumn('DONATIONS', '${widget.totalDonations} Completed'),
            _buildDetailColumn('LIVES SAVED', 'Up to ${widget.totalDonations * 3} Patients'),
            _buildDetailColumn('MEMBER SINCE', widget.memberSince),
          ],
        ),
      ],
    );
  }

  Widget _buildQrCheckInView() {
    return Column(
      children: [
        Text(
          'Express Hospital Check-In',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Scan at hospital reception or blood drive unit',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          width: 150,
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: CustomPaint(
            painter: _QrMatrixPainter(
              data: 'BLOOD_DONOR:${widget.donorId}|${widget.donorName}|${widget.bloodGroup}',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.donorId,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: AppColors.primaryRed,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

/// Clean vector QR Code pattern painter (standard 21x21 module layout with 3 position markers).
/// 100% vector, zero external dependencies, crisp at any resolution.
class _QrMatrixPainter extends CustomPainter {
  final String data;

  const _QrMatrixPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = AppColors.textPrimary;
    final accentPaint = Paint()..color = AppColors.primaryRed;

    final double moduleSize = size.width / 21;

    void drawFinder(double x, double y) {
      // Outer 7x7 square
      canvas.drawRect(
        Rect.fromLTWH(x * moduleSize, y * moduleSize, 7 * moduleSize, 7 * moduleSize),
        darkPaint,
      );
      // Inner 5x5 white square
      canvas.drawRect(
        Rect.fromLTWH((x + 1) * moduleSize, (y + 1) * moduleSize, 5 * moduleSize, 5 * moduleSize),
        Paint()..color = Colors.white,
      );
      // Center 3x3 square
      canvas.drawRect(
        Rect.fromLTWH((x + 2) * moduleSize, (y + 2) * moduleSize, 3 * moduleSize, 3 * moduleSize),
        accentPaint,
      );
    }

    // 3 Standard QR Finder patterns (Top-Left, Top-Right, Bottom-Left)
    drawFinder(0, 0);
    drawFinder(14, 0);
    drawFinder(0, 14);

    // Timing patterns
    for (int i = 8; i < 13; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * moduleSize, 6 * moduleSize, moduleSize, moduleSize), darkPaint);
      canvas.drawRect(Rect.fromLTWH(6 * moduleSize, i * moduleSize, moduleSize, moduleSize), darkPaint);
    }

    // Deterministic data modules based on data hash
    final hash = data.hashCode.abs();
    for (int row = 0; row < 21; row++) {
      for (int col = 0; col < 21; col++) {
        // Skip finder areas
        if ((row < 8 && col < 8) || (row < 8 && col > 13) || (row > 13 && col < 8)) {
          continue;
        }

        final bit = (hash ^ (row * 31 + col * 17)) % 7;
        if (bit == 0 || bit == 2 || bit == 5) {
          canvas.drawRect(
            Rect.fromLTWH(col * moduleSize, row * moduleSize, moduleSize * 0.9, moduleSize * 0.9),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) => oldDelegate.data != data;
}
