import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../../notifications/data/push_notification_service.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../domain/models/sos_broadcast.dart';
import '../controllers/sos_controller.dart';
import '../widgets/expanding_radar_visualizer.dart';
import '../widgets/hold_to_confirm_sos_button.dart';
import '../widgets/responder_coordination_sheet.dart';

/// Full-screen emergency SOS broadcast system with hold-to-confirm trigger,
/// expanding geofence radar, and real-time donor response tracking.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  String _selectedBloodGroup = 'O-';
  String _selectedHospitalId = 'hosp_001';
  final TextEditingController _contactController = TextEditingController(text: '+1 415-555-9911');

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _startSosBroadcast() async {
    final hospital = MockSeedData.hospitals.firstWhere(
      (h) => h.id == _selectedHospitalId,
      orElse: () => MockSeedData.hospitals.first,
    );

    final repo = ref.read(sosRepositoryProvider);
    final broadcast = await repo.startBroadcast(
      bloodGroup: _selectedBloodGroup,
      hospitalName: hospital.name,
      contactNumber: _contactController.text.trim(),
    );

    // Also dispatch high-priority notification to notification center
    final notifRepo = ref.read(notificationsRepositoryProvider);
    await notifRepo.addNotification(
      AppNotification(
        id: 'notif_sos_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        title: '🚨 EMERGENCY SOS ACTIVE',
        body: 'Emergency broadcast for $_selectedBloodGroup at ${hospital.name} reaching donors within 5 km.',
        type: 'sos',
        read: false,
        createdAt: DateTime.now(),
        data: {'sosId': broadcast.id},
      ),
    );

    await ref.read(pushNotificationServiceProvider).showLocalNotification(
      title: '🚨 EMERGENCY SOS ACTIVE',
      body: 'Emergency broadcast for $_selectedBloodGroup at ${hospital.name} reaching donors within 5 km.',
      payload: '/sos',
      isEmergency: true,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Emergency SOS alert broadcasted to nearby donors!'),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }

  Future<void> _resolveSos(String broadcastId) async {
    final repo = ref.read(sosRepositoryProvider);
    await repo.resolveBroadcast(broadcastId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Emergency SOS resolved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String broadcastId) {
    String cancelReason = 'Donor found via other channel';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Cancel Emergency SOS?', style: AppTextStyles.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to stop broadcasting this emergency alert to donors?',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: cancelReason,
                decoration: InputDecoration(
                  labelText: 'Reason for cancellation',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Donor found via other channel', child: Text('Donor found via other channel')),
                  DropdownMenuItem(value: 'Patient transferred', child: Text('Patient transferred')),
                  DropdownMenuItem(value: 'Accidental trigger', child: Text('Accidental trigger')),
                  DropdownMenuItem(value: 'Other medical reason', child: Text('Other medical reason')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => cancelReason = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(sosRepositoryProvider).cancelBroadcast(broadcastId, reason: cancelReason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final broadcastAsync = ref.watch(activeSosBroadcastProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency SOS Broadcast'),
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
      ),
      body: LifeLineBackground(
        child: broadcastAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryRed),
          ),
          error: (err, _) => Center(
            child: Text('Error: $err', style: AppTextStyles.bodyMedium),
          ),
          data: (broadcast) {
            if (broadcast != null && broadcast.isBroadcasting) {
              return _buildLiveBroadcastView(context, broadcast);
            }
            return _buildPreBroadcastTriggerView(context);
          },
        ),
      ),
    );
  }

  // 1. PRE-BROADCAST TRIGGER VIEW
  Widget _buildPreBroadcastTriggerView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Alert Badge Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightRedTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryRed),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, color: AppColors.primaryRed, size: 16),
                SizedBox(width: 6),
                Text(
                  'HIGH-PRIORITY RED ALERT',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Emergency Donor SOS',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Instantly notifies all active compatible donors in a 5km radius, automatically expanding to 25km if units remain unfulfilled.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Blood Group Selection
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Urgent Blood Group Needed', style: AppTextStyles.titleSmall),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BloodCompatibility.allBloodGroups.map((group) {
              final isSelected = _selectedBloodGroup == group;
              return ChoiceChip(
                label: Text(group),
                selected: isSelected,
                selectedColor: AppColors.primaryRed,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryDark : AppColors.border,
                  width: 1.5,
                ),
                onSelected: (_) => setState(() => _selectedBloodGroup = group),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Hospital Dropdown
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Emergency Center / Hospital', style: AppTextStyles.titleSmall),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedHospitalId,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              prefixIcon: const Icon(Icons.local_hospital_rounded, color: AppColors.primaryRed),
            ),
            items: MockSeedData.hospitals.map((h) {
              return DropdownMenuItem(
                value: h.id,
                child: Text(h.name, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedHospitalId = val);
            },
          ),

          const SizedBox(height: 20),

          // Desk Contact Number
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Emergency Desk Contact Number', style: AppTextStyles.titleSmall),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primaryRed),
            ),
          ),

          const SizedBox(height: 36),

          // 2-Second Hold-to-Confirm Trigger Button
          HoldToConfirmSosButton(
            onTriggered: _startSosBroadcast,
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Press and hold for 2 seconds to activate broadcast',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 2. LIVE BROADCAST IN PROGRESS VIEW
  Widget _buildLiveBroadcastView(BuildContext context, SosBroadcast broadcast) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Live Alert Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightRedTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryRed, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'LIVE EMERGENCY BROADCAST',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Radar Geofence Visualization
          ExpandingRadarVisualizer(
            currentRadiusKm: broadcast.radiusKm,
            notifiedCount: broadcast.notifiedCount,
            acceptedCount: broadcast.acceptedCount,
          ),

          const SizedBox(height: 24),

          // 3 Live Metric Badges
          Row(
            children: [
              _buildMetricCard(
                title: 'Search Radius',
                value: '${broadcast.radiusKm.toInt()} km',
                icon: Icons.radar_rounded,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: 10),
              _buildMetricCard(
                title: 'Donors Alerted',
                value: '${broadcast.notifiedCount}',
                icon: Icons.notifications_active_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              _buildMetricCard(
                title: 'Responders',
                value: '${broadcast.acceptedCount}',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Broadcast Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          BloodGroupChip(
                            bloodGroup: broadcast.bloodGroup ?? 'O-',
                            fontSize: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  broadcast.hospitalName ?? 'Emergency Center',
                                  style: AppTextStyles.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Auto-expanding coverage every 6s',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => ref.read(sosRepositoryProvider).simulateDonorAcceptance(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightRedTint,
                        foregroundColor: AppColors.primaryRed,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Simulate +1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 1. Responding Donors Section
          _buildRespondersSection(context, broadcast),

          const SizedBox(height: 20),

          // 2. Hospital & Blood Bank Reserve Stock Check Card
          _buildHospitalReserveCard(context, broadcast),

          const SizedBox(height: 20),

          // 3. Live Dispatch & Event Timeline Log
          _buildTimelineLogsSection(broadcast),

          const SizedBox(height: 24),

          // Action Buttons: Resolve / Cancel
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context, broadcast.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel SOS', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _resolveSos(broadcast.id),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('Resolve Emergency', style: TextStyle(fontWeight: FontWeight.bold)),
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

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // 1. Responders Section with coordination modal trigger
  Widget _buildRespondersSection(BuildContext context, SosBroadcast broadcast) {
    final responders = broadcast.responders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Responders (${responders.length})',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            if (responders.isNotEmpty)
              const Text(
                'Tap card to coordinate',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (responders.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.lightRedTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radar_rounded, color: AppColors.primaryRed, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scanning & Awaiting First Responder',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Alert dispatched to active donors within ${broadcast.radiusKm.toInt()} km.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...responders.map((responder) {
            final isArrivalOrBeyond = responder.hasArrived || responder.isDrawing || responder.isCompleted;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isArrivalOrBeyond ? AppColors.success : AppColors.primaryRed,
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ResponderCoordinationSheet(responder: responder),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        BloodGroupChip(bloodGroup: responder.bloodGroup, fontSize: 13),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(responder.name, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                '${responder.distanceKm.toStringAsFixed(1)} km away • ${responder.transportMode}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isArrivalOrBeyond ? AppColors.success.withValues(alpha: 0.12) : AppColors.lightRedTint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isArrivalOrBeyond ? AppColors.success : AppColors.primaryRed),
                                ),
                                child: Text(
                                  responder.formattedStatus,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isArrivalOrBeyond ? AppColors.success : AppColors.primaryRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => _makeCall(responder.phone),
                          icon: const Icon(Icons.phone_rounded, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(34, 34),
                          ),
                          tooltip: 'Call Responder',
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // 2. Hospital & Blood Bank Stock Check Card
  Widget _buildHospitalReserveCard(BuildContext context, SosBroadcast broadcast) {
    final bloodGroup = broadcast.bloodGroup ?? 'O-';
    final hospital = MockSeedData.hospitals.firstWhere(
      (h) => h.name == broadcast.hospitalName,
      orElse: () => MockSeedData.hospitals.first,
    );
    final bloodBank = MockSeedData.hospitals.firstWhere(
      (h) => h.type == 'blood_bank',
      orElse: () => MockSeedData.hospitals[1],
    );

    final hospUnits = hospital.bloodStock[bloodGroup] ?? 0;
    final bankUnits = bloodBank.bloodStock[bloodGroup] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.inventory_2_rounded, size: 18, color: AppColors.primaryRed),
              const SizedBox(width: 8),
              Text(
                'Hospital & Blood Bank Reserve',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Destination Hospital Stock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hospital.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Text('Destination Emergency Center', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hospUnits <= 3 ? AppColors.lightRedTint : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hospUnits <= 3 ? AppColors.primaryRed : AppColors.border),
                ),
                child: Text(
                  '$hospUnits Units in Stock',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hospUnits <= 3 ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // Blood Bank Backup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bloodBank.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Text('Emergency Blood Bank Backup', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$bankUnits Units',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _makeCall(bloodBank.phone),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                    ),
                    tooltip: 'Call Blood Bank Desk',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Real-time Dispatch & Event Timeline Logs
  Widget _buildTimelineLogsSection(SosBroadcast broadcast) {
    if (broadcast.timelineLogs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Live Dispatch & Event Log',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: broadcast.timelineLogs.reversed.take(6).map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.fiber_manual_record, size: 6, color: AppColors.primaryRed),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
