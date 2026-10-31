import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _weightController;

  String _selectedBloodGroup = 'O+';
  String _selectedGender = 'unspecified';
  DateTime? _selectedDob;
  bool _isDonor = true;
  bool _initialized = false;
  bool _isSaving = false;

  final List<String> _genderOptions = ['female', 'male', 'non-binary', 'unspecified'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final profile = ref.read(profileControllerProvider).value;
      _nameController = TextEditingController(text: profile?.name ?? '');
      _phoneController = TextEditingController(text: profile?.phone ?? '');
      _cityController = TextEditingController(text: profile?.city ?? '');
      _weightController = TextEditingController(
        text: profile?.weight != null ? profile!.weight!.toInt().toString() : '',
      );
      _selectedBloodGroup = profile?.bloodGroup ?? 'O+';
      _selectedGender = profile?.gender ?? 'unspecified';
      _selectedDob = profile?.dob;
      _isDonor = profile?.isDonor ?? true;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1998, 5, 20),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // At least 18 yrs old for clinical eligibility
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
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final current = ref.read(profileControllerProvider).value;
    if (current == null) return;

    setState(() => _isSaving = true);

    final updated = current.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      weight: double.tryParse(_weightController.text.trim()),
      bloodGroup: _selectedBloodGroup,
      gender: _selectedGender,
      dob: _selectedDob,
      isDonor: _isDonor,
    );

    final success = await ref.read(profileControllerProvider.notifier).updateProfile(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primaryRed),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryRed),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone' : null,
              ),
              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'City / Neighborhood',
                  prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.primaryRed),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter city' : null,
              ),
              const SizedBox(height: 16),

              // Weight (kg)
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.primaryRed),
                  hintText: 'e.g. 68',
                ),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    final w = double.tryParse(v.trim());
                    if (w == null) return 'Please enter a valid weight number';
                    if (_isDonor && w < 45) return 'Minimum 45 kg required for blood donation eligibility';
                    if (w < 30 || w > 250) return 'Please enter a realistic weight (30-250 kg)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc_rounded, color: AppColors.primaryRed),
                ),
                items: _genderOptions.map((g) {
                  return DropdownMenuItem(
                    value: g,
                    child: Text(g[0].toUpperCase() + g.substring(1)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGender = val);
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth Picker Tile
              InkWell(
                onTap: _pickDateOfBirth,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primaryRed, size: 20),
                      const SizedBox(width: 14),
                      Text(
                        _selectedDob != null
                            ? 'DOB: ${DateFormat('dd MMM yyyy').format(_selectedDob!)}'
                            : 'Select Date of Birth',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Blood Group Selection
              Text(
                'Blood Group',
                style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BloodCompatibility.allBloodGroups.map((group) {
                  final isSelected = _selectedBloodGroup == group;
                  return BloodGroupChip(
                    bloodGroup: group,
                    isSelected: isSelected,
                    onSelected: (_) => setState(() => _selectedBloodGroup = group),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Voluntary Donor Switch Tile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Voluntary Donor',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Allow recipients to discover you in emergency searches',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isDonor,
                      activeThumbColor: AppColors.primaryRed,
                      onChanged: (val) => setState(() => _isDonor = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              PrimaryButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
