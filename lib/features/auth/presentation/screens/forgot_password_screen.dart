import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await ref.read(authControllerProvider.notifier).sendPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LifeLineBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.lightRedTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_rounded, size: 36, color: AppColors.primaryRed),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Forgot Your Password?',
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered email address below. We will send you instructions to reset your password.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  if (_submitted) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Password reset link dispatched! Please check your inbox and follow the instructions.',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Registered Email',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryRed),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email';
                        if (!v.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Send Reset Link',
                      isLoading: _isLoading,
                      onPressed: _handleReset,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
