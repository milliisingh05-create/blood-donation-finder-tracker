import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/sos/presentation/controllers/sos_controller.dart';
import '../theme/app_colors.dart';

/// App shell hosting the 5 primary tabs with a persistent Material 3 bottom navigation bar.
/// Strictly uses flat colors: normal #2B1A1C, selected #FF4B5C, tint #FFE3E6. Zero gradients.
class MainNavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSosAsync = ref.watch(activeSosBroadcastProvider);
    final isSosLive = activeSosAsync.value?.isBroadcasting ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          backgroundColor: AppColors.surface,
          elevation: 0,
          indicatorColor: AppColors.lightRedTint,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryRed),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_search_outlined),
              selectedIcon: Icon(Icons.person_search_rounded, color: AppColors.primaryRed),
              label: 'Find Donors',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: isSosLive,
                backgroundColor: AppColors.primaryRed,
                smallSize: 8,
                child: const Icon(Icons.emergency_outlined),
              ),
              selectedIcon: const Icon(Icons.emergency_rounded, color: AppColors.primaryRed),
              label: 'SOS',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_edu_outlined),
              selectedIcon: Icon(Icons.history_edu_rounded, color: AppColors.primaryRed),
              label: 'History',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primaryRed),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
