import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../domain/models/donation_request.dart';
import '../controllers/requests_controller.dart';

/// Screen allowing patients, doctors, or family members to broadcast an urgent blood request.
class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedBloodGroup = 'O+';
  int _units = 2;
  String _urgency = 'urgent'; // 'normal', 'urgent', 'critical'
  String _selectedHospitalId = 'hosp_001';
  final TextEditingController _contactController = TextEditingController(text: '+1 415-555-9080');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController(text: 'Johnathan Miller');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _contactController.dispose();
    _notesController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final hospital = MockSeedData.hospitals.firstWhere(
      (h) => h.id == _selectedHospitalId,
      orElse: () => MockSeedData.hospitals.first,
    );

    final newRequest = DonationRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      requesterId: 'current_user',
      requesterName: _patientNameController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      units: _units,
      urgency: _urgency,
      hospitalId: hospital.id,
      hospitalName: hospital.name,
      latitude: hospital.latitude,
      longitude: hospital.longitude,
      geohash: hospital.geohash,
      contactNumber: _contactController.text.trim(),
      note: _notesController.text.trim(),
      status: 'open',
      createdAt: DateTime.now(),
    );

    final repo = ref.read(requestsRepositoryProvider);
    final matchedDonorsCount = await repo.createRequest(newRequest);

    // Also add to in-app notification center for demo visibility
    final notifRepo = ref.read(notificationsRepositoryProvider);
    await notifRepo.addNotification(
      AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        title: _urgency == 'critical' ? '🚨 Critical Request Broadcasted' : '🩸 Blood Request Active',
        body: 'Your request for $_units units of $_selectedBloodGroup at ${hospital.name} reached $matchedDonorsCount donors.',
        type: _urgency == 'critical' ? 'sos' : 'request',
        read: false,
        createdAt: DateTime.now(),
        data: {'requestId': newRequest.id},
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _showSuccessDialog(newRequest, matchedDonorsCount);
  }

  void _showSuccessDialog(DonationRequest request, int matchedDonorsCount) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.lightRedTint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryRed, width: 2),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryRed, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Broadcast Successful!',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your request for ${request.units} units of ${request.bloodGroup} has been broadcasted to $matchedDonorsCount compatible active donors nearby.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutePaths.requests);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('View All Requests', style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/requests/${request.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Request Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compatibleDonors = BloodCompatibility.getCompatibleDonorsFor(_selectedBloodGroup);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Blood'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Blood Group Selection
              Text('Required Blood Group', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
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
                      fontSize: 14,
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

              const SizedBox(height: 12),

              // Compatibility Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Compatible Donors: ${compatibleDonors.join(", ")}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Units Needed Stepper
              Text('Units Needed (Bags)', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_units unit${_units > 1 ? "s" : ""} (~${_units * 450} mL)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: _units > 1 ? () => setState(() => _units--) : null,
                          icon: const Icon(Icons.remove, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.lightRedTint,
                            foregroundColor: AppColors.primaryRed,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_units',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _units < 10 ? () => setState(() => _units++) : null,
                          icon: const Icon(Icons.add, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Urgency Selector
              Text('Urgency Level', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildUrgencyOption(
                    key: 'normal',
                    label: 'Normal',
                    subtitle: 'Within 48h',
                    icon: Icons.access_time_rounded,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  _buildUrgencyOption(
                    key: 'urgent',
                    label: 'Urgent',
                    subtitle: 'Within 12h',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _buildUrgencyOption(
                    key: 'critical',
                    label: 'Critical',
                    subtitle: 'Immediate ICU',
                    icon: Icons.local_hospital_rounded,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Hospital Selection
              Text('Receiving Hospital / Blood Bank', style: AppTextStyles.titleMedium),
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
                  prefixIcon: const Icon(Icons.local_hospital_outlined, color: AppColors.primaryRed),
                ),
                items: MockSeedData.hospitals.map((h) {
                  return DropdownMenuItem(
                    value: h.id,
                    child: Text(
                      h.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedHospitalId = val);
                },
              ),

              const SizedBox(height: 20),

              // 5. Patient Name
              Text('Patient Full Name', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _patientNameController,
                decoration: InputDecoration(
                  hintText: 'Enter patient full name',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter patient name' : null,
              ),

              const SizedBox(height: 20),

              // 6. Contact Phone Number
              Text('Contact Phone (Verified at Desk)', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+1 415-555-0100',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                ),
                validator: (val) => val == null || val.trim().length < 7 ? 'Enter a valid contact number' : null,
              ),

              const SizedBox(height: 20),

              // 7. Clinical Notes / Details
              Text('Clinical Notes & Urgency Details', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., Surgery scheduled for ICU Bed 4, road trauma casualty, blood units urgently required.',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 8. Submit Button
              PrimaryButton(
                text: _urgency == 'critical' ? 'Broadcast Emergency Request' : 'Submit Blood Request',
                isLoading: _isSubmitting,
                icon: Icons.send_rounded,
                onPressed: _submitRequest,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyOption({
    required String key,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _urgency == key;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _urgency = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.lightRedTint : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryRed : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primaryRed : AppColors.textSecondary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
