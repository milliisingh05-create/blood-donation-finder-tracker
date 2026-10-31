import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/lifeline_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController(text: '+1 415-555-0101');
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    await repo.verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _verificationId = verificationId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryRed,
            content: Text(
              verificationId.startsWith('offline_vid')
                  ? 'Verification code sent! (Offline testing code: 123456)'
                  : 'Verification code sent to $phone',
            ),
          ),
        );
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryDark,
            content: Text(errorMessage),
          ),
        );
      },
      onAutoVerified: (user) {
        if (!mounted) return;
        ref.read(authControllerProvider.notifier).setAuthenticated(user);
        try {
          context.go(AppRoutePaths.dashboard);
        } catch (_) {}
      },
    );
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit verification code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final success = await ref.read(authControllerProvider.notifier).signInWithPhoneOtp(
          verificationId: _verificationId ?? 'offline_vid_${phone.hashCode}',
          smsCode: code,
          phoneNumber: phone,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        try {
          context.go(AppRoutePaths.dashboard);
        } catch (_) {}
      }
    } else {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Verification failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.primaryDark, content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phone OTP Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LifeLineBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                  child: const Icon(Icons.phone_android_rounded, size: 36, color: AppColors.primaryRed),
                ),
                const SizedBox(height: 20),
                Text(
                  _otpSent ? 'Enter 6-Digit Code' : 'Phone Verification',
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  _otpSent
                      ? 'We sent a verification SMS to ${_phoneController.text}'
                      : 'Enter your mobile number to receive an instant verification code.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 28),

                if (!_otpSent) ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryRed),
                      hintText: '+1 415-555-0101',
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Send Verification Code',
                    isLoading: _isLoading,
                    onPressed: _sendOtp,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      labelText: '6-Digit Code',
                      hintText: '123456',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Verify & Sign In',
                    isLoading: _isLoading,
                    onPressed: _verifyOtp,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: const Text('Change Phone Number'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
