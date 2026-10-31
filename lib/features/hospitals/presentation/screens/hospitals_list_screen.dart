import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../domain/models/hospital.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/hospitals_controller.dart';
import '../widgets/hospital_detail_modal.dart';
import '../widgets/hospital_map_view.dart';
import '../widgets/update_stock_modal.dart';

/// Hospitals and Blood Banks directory & interactive map locator screen.
/// Features dual-engine map view, real-time stock inventory, critical shortage alerts,
/// direct desk calling, GPS directions, and staff inventory updating.
class HospitalsListScreen extends ConsumerStatefulWidget {
  const HospitalsListScreen({super.key});

  @override
  ConsumerState<HospitalsListScreen> createState() => _HospitalsListScreenState();
}

class _HospitalsListScreenState extends ConsumerState<HospitalsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isMapView = false;
  HospitalWithDistance? _selectedHospital;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling $phone')),
      );
    }
  }

  Future<void> _openDirections(double lat, double lng, String name) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigating to $name')),
      );
    }
  }

  void _showUpdateStockModal(BuildContext context, Hospital hospital) {
    final profile = ref.read(profileControllerProvider).value;
    final isStaff = profile?.isStaffOrAdmin ?? false;

    if (!isStaff) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.security_rounded, color: AppColors.primaryRed, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Staff Access Only', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Direct blood inventory modifications are restricted to verified medical center staff and inventory administrators under clinical compliance rules.',
                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded, size: 18, color: AppColors.primaryRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hospital.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(profileControllerProvider.notifier).setRole('staff');
                _openUpdateStockModal(context, hospital);
              },
              child: const Text('Authorize as Staff'),
            ),
          ],
        ),
      );
      return;
    }

    _openUpdateStockModal(context, hospital);
  }

  void _openUpdateStockModal(BuildContext context, Hospital hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpdateStockModal(hospital: hospital),
    );
  }

  void _showHospitalDetailModal(BuildContext context, HospitalWithDistance item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HospitalDetailModal(
        hospital: item.hospital,
        formattedDistance: item.formattedDistance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsList = ref.watch(filteredHospitalsProvider);
    final filter = ref.watch(hospitalsFilterNotifierProvider);
    final filterNotifier = ref.read(hospitalsFilterNotifierProvider.notifier);
    final hasAnyCritical = hospitalsList.any((h) => h.hospital.bloodStock.values.any((u) => u < 3));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hospitals & Blood Banks'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutePaths.dashboard);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMapView ? Icons.view_list_rounded : Icons.map_rounded,
              color: AppColors.primaryRed,
            ),
            tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map Locator',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Controls Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => filterNotifier.setQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search hospitals, blood banks, or city...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primaryRed),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              filterNotifier.setQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Facility Type & Shortage Filter Row
                Row(
                  children: [
                    _buildTypeChip('all', 'All Facilities'),
                    const SizedBox(width: 6),
                    _buildTypeChip('hospital', 'Hospitals'),
                    const SizedBox(width: 6),
                    _buildTypeChip('blood_bank', 'Blood Banks'),
                    const Spacer(),
                    FilterChip(
                      label: const Text('Shortages (<3)'),
                      selected: filter.criticalOnly,
                      selectedColor: AppColors.lightRedTint,
                      checkmarkColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: filter.criticalOnly ? AppColors.primaryRed : AppColors.textPrimary,
                      ),
                      side: BorderSide(
                        color: filter.criticalOnly ? AppColors.primaryRed : AppColors.border,
                      ),
                      onSelected: (val) => filterNotifier.setCriticalOnly(val),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Blood Group Pills Row
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('All Blood Stock'),
                          selected: filter.bloodGroup == null,
                          selectedColor: AppColors.primaryRed,
                          backgroundColor: AppColors.background,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: filter.bloodGroup == null ? Colors.white : AppColors.textPrimary,
                          ),
                          side: BorderSide(
                            color: filter.bloodGroup == null ? AppColors.primaryDark : AppColors.border,
                          ),
                          onSelected: (_) => filterNotifier.setBloodGroup(null),
                        ),
                      ),
                      ...BloodCompatibility.allBloodGroups.map((group) {
                        final isSelected = filter.bloodGroup == group;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(group),
                            selected: isSelected,
                            selectedColor: AppColors.primaryRed,
                            backgroundColor: AppColors.background,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryDark : AppColors.border,
                            ),
                            onSelected: (_) => filterNotifier.setBloodGroup(group),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Critical Shortage Alert Banner (List Mode)
          if (!_isMapView && hasAnyCritical && !filter.criticalOnly)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightRedTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.primaryRed, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Urgent: Critical shortages (<3 units) detected nearby',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                  TextButton(
                    onPressed: () => filterNotifier.setCriticalOnly(true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Filter Shortages', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                  ),
                ],
              ),
            ),

          // 3. Content Body: Map Locator vs Directory List
          Expanded(
            child: _isMapView
                ? _buildMapViewContent(context, hospitalsList)
                : _buildListViewContent(context, hospitalsList),
          ),
        ],
      ),
    );
  }

  Widget _buildMapViewContent(BuildContext context, List<HospitalWithDistance> hospitalsList) {
    return Stack(
      children: [
        HospitalMapView(
          centerLat: LocationService.defaultLatitude,
          centerLng: LocationService.defaultLongitude,
          hospitals: hospitalsList,
          selectedHospital: _selectedHospital,
          onHospitalTap: (item) => setState(() => _selectedHospital = item),
        ),
        if (_selectedHospital != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildMapPreviewCard(context, _selectedHospital!),
          ),
      ],
    );
  }

  Widget _buildMapPreviewCard(BuildContext context, HospitalWithDistance item) {
    final h = item.hospital;
    final totalUnits = h.totalStockUnits;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryRed, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: h.isBloodBank
                      ? const Color(0xFF2980B9).withValues(alpha: 0.12)
                      : AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  h.isBloodBank ? Icons.bloodtype_rounded : Icons.local_hospital_rounded,
                  color: h.isBloodBank ? const Color(0xFF2980B9) : AppColors.primaryRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.formattedDistance} • $totalUnits units in stock',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _selectedHospital = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makeCall(h.phone),
                  icon: const Icon(Icons.phone_rounded, size: 14, color: AppColors.primaryRed),
                  label: const Text('Call', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDirections(h.latitude, h.longitude, h.name),
                  icon: const Icon(Icons.directions_rounded, size: 14, color: Color(0xFF2980B9)),
                  label: const Text('Directions', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showHospitalDetailModal(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListViewContent(BuildContext context, List<HospitalWithDistance> hospitalsList) {
    if (hospitalsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryRed),
                ),
                child: const Icon(Icons.local_hospital_outlined, size: 32, color: AppColors.primaryRed),
              ),
              const SizedBox(height: 16),
              Text('No Facilities Found', style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              const Text(
                'Try adjusting your search query or filters.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: hospitalsList.length,
      itemBuilder: (ctx, idx) => _buildHospitalCard(context, hospitalsList[idx]),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final current = ref.watch(hospitalsFilterNotifierProvider).type;
    final isSelected = current == type;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryRed,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryDark : AppColors.border,
      ),
      onSelected: (_) => ref.read(hospitalsFilterNotifierProvider.notifier).setType(type),
    );
  }

  Widget _buildHospitalCard(BuildContext context, HospitalWithDistance item) {
    final h = item.hospital;
    final totalUnits = h.totalStockUnits;

    return InkWell(
      onTap: () => _showHospitalDetailModal(context, item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name & Type pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: h.isBloodBank
                        ? const Color(0xFF2980B9).withValues(alpha: 0.12)
                        : AppColors.lightRedTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    h.isBloodBank ? Icons.bloodtype_rounded : Icons.local_hospital_rounded,
                    color: h.isBloodBank ? const Color(0xFF2980B9) : AppColors.primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.name,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            item.formattedDistance,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${h.isBloodBank ? "Blood Bank" : "Hospital"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Total Stock badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$totalUnits units',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    h.address,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Live Stock Matrix
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: BloodCompatibility.allBloodGroups.map((group) {
                final units = h.stockFor(group);
                final isCritical = units < 3;
                final isLow = units >= 3 && units <= 5;

                final Color badgeColor = isCritical
                    ? AppColors.primaryRed
                    : isLow
                        ? AppColors.warning
                        : AppColors.success;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        group,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$units',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Actions Row
            Row(
              children: [
                // Call Desk
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makeCall(h.phone),
                    icon: const Icon(Icons.phone_rounded, size: 15, color: AppColors.primaryRed),
                    label: const Text('Call Desk', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Directions
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(h.latitude, h.longitude, h.name),
                    icon: const Icon(Icons.directions_rounded, size: 15, color: Color(0xFF2980B9)),
                    label: const Text('Directions', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Staff Update Stock
                IconButton.filled(
                  onPressed: () => _showUpdateStockModal(context, h),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  tooltip: 'Staff: Update Stock',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.lightRedTint,
                    foregroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
