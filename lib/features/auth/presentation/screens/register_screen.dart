import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../../../core/widgets/blood_group_chip.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController(text: 'San Francisco');

  String _selectedBloodGroup = 'O+';
  bool _isDonor = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).registerWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          bloodGroup: _selectedBloodGroup,
          city: _cityController.text.trim(),
          isDonor: _isDonor,
        );

    if (!mounted) return;

    if (success) {
      if (mounted) {
        context.go(AppRoutePaths.permissions);
      }
    } else {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LifeLineBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join Blood Finder',
                    style: AppTextStyles.displayMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Become a registered donor or search for urgent blood.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 24),

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
                      hintText: '+1 415-555-0199',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
                      if (v.trim().length < 8) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryRed),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter an email';
                      if (!v.contains('@')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryRed),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 16),

                  // City
                  TextFormField(
                    controller: _cityController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'City / District',
                      prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.primaryRed),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your city' : null,
                  ),
                  const SizedBox(height: 20),

                  // Blood Group Selector
                  Text(
                    'Select Blood Group',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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

                  // Donor Status Toggle
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
                                'I want to be a donor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Register as voluntary donor to appear on the emergency map',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
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
                  const SizedBox(height: 28),

                  // Register Button
                  PrimaryButton(
                    text: 'Complete Registration',
                    isLoading: authState.isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
