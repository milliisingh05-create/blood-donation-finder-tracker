import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Production error boundary widget replacing the default Flutter red screen.
/// Renders a calm, user-friendly message with recovery options adhering to
/// the flat light-red design system.
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? details;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error shield icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.lightRedTint,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryRed, width: 2),
                  ),
                  child: const Icon(
                    Icons.healing_rounded,
                    color: AppColors.primaryRed,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Something Went Wrong',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                const Text(
                  'An unexpected visual rendering error occurred. Your health records and critical donation requests remain completely secure.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (kDebugMode && details != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      details!.exceptionAsString(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                ElevatedButton.icon(
                  onPressed: onRetry ??
                      () {
                        final navigator = Navigator.maybeOf(context);
                        if (navigator != null && navigator.canPop()) {
                          navigator.pop();
                        }
                      },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reload Screen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
