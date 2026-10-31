import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/blood_compatibility.dart';
import '../../../../core/router/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/donor_finder_repository.dart';
import '../controllers/donor_finder_controller.dart';
import '../widgets/app_map_view.dart';
import '../widgets/staggered_donor_card.dart';

/// Interactive GPS Donor Finder screen.
/// Features dual-engine map (FlutterMap/OSM + Google Maps fallback),
/// distance radius filters (1km, 5km, 10km, 25km), blood group chips,
/// and privacy-guarded donor contact actions.
class DonorFinderScreen extends ConsumerStatefulWidget {
  const DonorFinderScreen({super.key});

  @override
  ConsumerState<DonorFinderScreen> createState() => _DonorFinderScreenState();
}

class _DonorFinderScreenState extends ConsumerState<DonorFinderScreen> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  static const List<double> _radiiKm = [1.0, 5.0, 10.0, 25.0];

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onDonorPinTapped(DiscoveredDonor donor) {
    ref.read(donorFinderControllerProvider.notifier).selectDonor(donor);
    // Expand bottom sheet slightly to show the selected donor
    if (_sheetController.isAttached && _sheetController.size < 0.45) {
      _sheetController.animateTo(
        0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showPrivacyProtectionDialog(BuildContext context, DiscoveredDonor donor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.lightRedTint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryRed, width: 1.5),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.primaryRed,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Donor Privacy Protection',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'To protect donors from unsolicited calls, phone numbers remain private until the donor accepts your blood request.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close', style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(AppRoutePaths.createRequest);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Request Blood', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final state = ref.watch(donorFinderControllerProvider);
    final controller = ref.read(donorFinderControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Dual-Engine Interactive Map Background
          Positioned.fill(
            child: AppMapView(
              centerLat: state.userLat,
              centerLng: state.userLng,
              donors: state.donors,
              selectedDonor: state.selectedDonor,
              onDonorTap: _onDonorPinTapped,
            ),
          ),

          // 2. Floating Top Filter Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top App Bar Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutePaths.dashboard);
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Find Nearby Donors',
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        // Active-Only Toggle Switch
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Active',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: state.activeOnly ? AppColors.success : AppColors.textSecondary,
                              ),
                            ),
                            Switch(
                              value: state.activeOnly,
                              activeThumbColor: AppColors.success,
                              onChanged: controller.toggleActiveOnly,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Radius Selector Pills Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radar_rounded, size: 18, color: AppColors.primaryRed),
                        const SizedBox(width: 8),
                        const Text(
                          'Radius:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _radiiKm.map((radius) {
                              final isSelected = state.selectedRadiusKm == radius;
                              return GestureDetector(
                                onTap: () => controller.setRadius(radius),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryRed : AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryDark : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    '${radius.toInt()} km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Horizontal Blood Group Selector
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // "All" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: const Text('All Groups'),
                            selected: state.selectedBloodGroup == null,
                            selectedColor: AppColors.primaryRed,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: state.selectedBloodGroup == null ? Colors.white : AppColors.textPrimary,
                            ),
                            side: BorderSide(
                              color: state.selectedBloodGroup == null ? AppColors.primaryDark : AppColors.border,
                            ),
                            onSelected: (_) => controller.setBloodGroup(null),
                          ),
                        ),
                        // Specific Blood Group chips
                        ...BloodCompatibility.allBloodGroups.map((group) {
                          final isSelected = state.selectedBloodGroup == group;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(group),
                              selected: isSelected,
                              selectedColor: AppColors.primaryRed,
                              backgroundColor: AppColors.surface,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryDark : AppColors.border,
                              ),
                              onSelected: (_) => controller.setBloodGroup(group),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Draggable Scrollable Bottom Sheet with Nearby Donors List
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.35,
            minChildSize: 0.16,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Grab Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nearby Donors (${state.donors.length})',
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Within ${state.selectedRadiusKm.toInt()} km • ${state.selectedBloodGroup ?? "All Groups"}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => context.push(AppRoutePaths.createRequest),
                          icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primaryRed),
                          label: const Text(
                            'Request Blood',
                            style: TextStyle(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 20),

                    // Loading State
                    if (state.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryRed),
                        ),
                      )
                    // Empty State
                    else if (state.donors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.lightRedTint,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryRed),
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                size: 30,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Donors Found in this Area',
                              style: AppTextStyles.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try expanding your search radius or selecting all blood groups.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                controller.setRadius(25.0);
                                controller.setBloodGroup(null);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Expand to 25 km & All Groups'),
                            ),
                          ],
                        ),
                      )
                    // Donors List
                    else
                      for (int i = 0; i < state.donors.length; i++)
                        StaggeredDonorCard(
                          donor: state.donors[i],
                          index: i,
                          isSelected: state.selectedDonor?.profile.uid == state.donors[i].profile.uid,
                          canCall: false, // Privacy guard: locked until donor accepts request
                          onCallTap: () => _showPrivacyProtectionDialog(context, state.donors[i]),
                          onRequestTap: () => context.push(AppRoutePaths.createRequest),
                        ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
