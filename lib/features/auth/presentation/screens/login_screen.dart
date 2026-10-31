import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'elena.rostova@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutePaths.dashboard);
    } else {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDemoLogin() async {
    final success = await ref.read(authControllerProvider.notifier).demoSignIn();
    if (!mounted) return;
    if (success) {
      context.go(AppRoutePaths.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LifeLineBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryDark, width: 2),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Greeting
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to find donors or manage requests',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryRed),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutePaths.forgotPassword),
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    PrimaryButton(
                      text: 'Sign In',
                      isLoading: authState.isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 14),

                    // Demo Mode Button (Only available in Debug Mode, disabled in Release)
                    if (kDebugMode) ...[
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.lightRedTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryRed, width: 1.5),
                        ),
                        child: TextButton.icon(
                          key: const Key('demo_mode_button'),
                          icon: const Icon(Icons.bolt_rounded, color: AppColors.primaryRed, size: 22),
                          label: Text(
                            'Demo Mode (Debug Only)',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: authState.isLoading ? null : _handleDemoLogin,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Debug Mode • Signs in as Marcus Chen (O+, Active Donor)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Phone Auth Alternative
                    OutlinedButton.icon(
                      icon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primaryRed, size: 18),
                      label: const Text('Sign In with Phone OTP'),
                      onPressed: () => context.push(AppRoutePaths.phoneAuth),
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Do not have an account? ',
                          style: AppTextStyles.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutePaths.register),
                          child: Text(
                            'Register Now',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
