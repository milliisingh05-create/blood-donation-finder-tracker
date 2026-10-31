import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/mock_seed_data.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/models/donation_record.dart';
import '../controllers/donations_controller.dart';

/// Screen allowing donors to log a verified donation, claim 100 points,
/// and update their 90-day medical interval countdown.
class RecordDonationScreen extends ConsumerStatefulWidget {
  final String? initialHospitalId;

  const RecordDonationScreen({super.key, this.initialHospitalId});

  @override
  ConsumerState<RecordDonationScreen> createState() => _RecordDonationScreenState();
}

class _RecordDonationScreenState extends ConsumerState<RecordDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedHospitalId = 'hosp_001';
  String _selectedBloodGroup = 'O-';
  String _selectedDonationType = 'Whole Blood';
  int _units = 1;
  DateTime _donationDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialHospitalId != null && widget.initialHospitalId!.isNotEmpty) {
      _selectedHospitalId = widget.initialHospitalId!;
    }
  }

  static const List<Map<String, dynamic>> donationTypeOptions = [
    {
      'type': 'Whole Blood',
      'label': 'Whole Blood',
      'recoveryDays': 90,
      'pointsPerUnit': 100,
      'volume': '~450 mL',
      'icon': Icons.water_drop_rounded,
      'desc': 'Standard blood donation (Red cells, plasma & platelets)',
    },
    {
      'type': 'Platelets',
      'label': 'Platelets',
      'recoveryDays': 14,
      'pointsPerUnit': 150,
      'volume': 'Apheresis',
      'icon': Icons.healing_rounded,
      'desc': 'Crucial for cancer patients & trauma recovery',
    },
    {
      'type': 'Plasma',
      'label': 'Plasma',
      'recoveryDays': 28,
      'pointsPerUnit': 120,
      'volume': 'Apheresis',
      'icon': Icons.shield_rounded,
      'desc': 'Contains antibodies and vital clotting proteins',
    },
  ];

  int get _pointsPerUnit {
    switch (_selectedDonationType) {
      case 'Platelets':
        return 150;
      case 'Plasma':
        return 120;
      case 'Whole Blood':
      default:
        return 100;
    }
  }

  int get _recoveryIntervalDays {
    switch (_selectedDonationType) {
      case 'Platelets':
        return 14;
      case 'Plasma':
        return 28;
      case 'Whole Blood':
      default:
        return 90;
    }
  }

  final TextEditingController _certCodeController =
      TextEditingController(text: 'CERT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
  final TextEditingController _hemoglobinController = TextEditingController(text: '14.5');
  final TextEditingController _bpController = TextEditingController(text: '120/80');

  bool _isSaving = false;

  @override
  void dispose() {
    _certCodeController.dispose();
    _hemoglobinController.dispose();
    _bpController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _donationDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _donationDate = picked);
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final hospital = MockSeedData.hospitals.firstWhere(
      (h) => h.id == _selectedHospitalId,
      orElse: () => MockSeedData.hospitals.first,
    );

    final calculatedPoints = _units * _pointsPerUnit;

    final newRecord = DonationRecord(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      donorId: 'current_user',
      donorName: 'Elena Rostova',
      hospitalId: hospital.id,
      hospitalName: hospital.name,
      bloodGroup: _selectedBloodGroup,
      donationType: _selectedDonationType,
      units: _units,
      date: _donationDate,
      verified: true,
      pointsEarned: calculatedPoints,
    );

    final repo = ref.read(donationsRepositoryProvider);
    await repo.recordDonation(newRecord);

    if (!mounted) return;
    setState(() => _isSaving = false);

    _showCelebrationDialog(newRecord);
  }

  void _showCelebrationDialog(DonationRecord record) {
    final nextEligibleDate = record.date.add(Duration(days: _recoveryIntervalDays));
    final dateFormat = DateFormat('MMMM d, yyyy');

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryRed, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Donation Verified!',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for donating ${record.units} unit(s) of ${record.bloodGroup} (${record.donationType}) at ${record.hospitalName}. Up to ${record.units * 3} lives saved!',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightRedTint.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${record.pointsEarned} Points Credited to Profile',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next eligible donation: ${dateFormat.format(nextEligibleDate)} ($_recoveryIntervalDays-day interval)',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutePaths.dashboard);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Dashboard', style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutePaths.donations);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('View Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Donation'),
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
              Text('Donation Center / Hospital', style: AppTextStyles.titleMedium),
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

              // Donation Type Selector (Whole Blood, Platelets, Plasma)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Donation Type', style: AppTextStyles.titleMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.lightRedTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_recoveryIntervalDays-Day Recovery',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: donationTypeOptions.map((opt) {
                  final type = opt['type'] as String;
                  final isSelected = _selectedDonationType == type;
                  final icon = opt['icon'] as IconData;
                  final recoveryDays = opt['recoveryDays'] as int;
                  final points = opt['pointsPerUnit'] as int;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: type != 'Plasma' ? 8 : 0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDonationType = type),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
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
                              Icon(
                                icon,
                                size: 20,
                                color: isSelected ? AppColors.primaryRed : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+$points Pts',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppColors.primaryRed : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${recoveryDays}d rest',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Text('Blood Group Donated', style: AppTextStyles.titleMedium),
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

              Text('Units Donated', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [1, 2].map((u) {
                  final isSelected = _units == u;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: u == 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _units = u),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.lightRedTint : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryRed : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$u Unit${u > 1 ? "s" : ""} (~${u * 450} mL)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Text('Donation Date', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.primaryRed, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            dateFormat.format(_donationDate),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Optional Clinical Vitals
              Text('Clinical Vitals (Optional)', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hemoglobinController,
                      decoration: InputDecoration(
                        labelText: 'Hemoglobin',
                        suffixText: 'g/dL',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _bpController,
                      decoration: InputDecoration(
                        labelText: 'Blood Pressure',
                        suffixText: 'mmHg',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text('Hospital Certificate / Stamp Code', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _certCodeController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.verified_outlined, color: AppColors.success),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter certificate code' : null,
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Record Donation & Claim +${_units * _pointsPerUnit} Pts',
                isLoading: _isSaving,
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submitDonation,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
