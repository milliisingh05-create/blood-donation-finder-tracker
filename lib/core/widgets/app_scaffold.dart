import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable application scaffold with flat background, standard padding, and optional app bar.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool safeArea;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.safeArea = true,
    this.padding,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          content,
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
