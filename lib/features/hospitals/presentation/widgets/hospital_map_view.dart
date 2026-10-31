import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/hospitals_controller.dart';

/// Interactive dual-engine map view for locating hospitals and blood banks.
/// Renders Google Maps if an API key is provided, and gracefully falls back to
/// FlutterMap + OpenStreetMap if there is no Maps API key.
class HospitalMapView extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final List<HospitalWithDistance> hospitals;
  final HospitalWithDistance? selectedHospital;
  final ValueChanged<HospitalWithDistance> onHospitalTap;

  const HospitalMapView({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.hospitals,
    this.selectedHospital,
    required this.onHospitalTap,
  });

  @override
  Widget build(BuildContext context) {
    if (AppConfig.hasGoogleMapsKey) {
      return _buildGoogleMap(context);
    }
    return _buildOpenStreetMap(context);
  }

  Widget _buildGoogleMap(BuildContext context) {
    final userPosition = gmaps.LatLng(centerLat, centerLng);

    final Set<gmaps.Marker> gMarkers = {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('user_live_location'),
        position: userPosition,
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
        infoWindow: const gmaps.InfoWindow(title: 'Your Location'),
      ),
      ...hospitals.map((item) {
        final h = item.hospital;
        final hasCritical = h.bloodStock.values.any((u) => u < 3);

        return gmaps.Marker(
          markerId: gmaps.MarkerId(h.id),
          position: gmaps.LatLng(h.latitude, h.longitude),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            h.isBloodBank ? gmaps.BitmapDescriptor.hueCyan : gmaps.BitmapDescriptor.hueRed,
          ),
          infoWindow: gmaps.InfoWindow(
            title: h.name,
            snippet: '${item.formattedDistance} • ${h.totalStockUnits} units in stock${hasCritical ? " (CRITICAL SHORTAGE)" : ""}',
          ),
          onTap: () => onHospitalTap(item),
        );
      }),
    };

    return Stack(
      children: [
        gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: userPosition,
            zoom: 13.0,
          ),
          markers: gMarkers,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
        ),
        _buildEngineBadge('Google Maps Engine'),
      ],
    );
  }

  Widget _buildOpenStreetMap(BuildContext context) {
    final userPosition = ll.LatLng(centerLat, centerLng);

    final List<Marker> markers = [
      // 1. User Location Pin (Blue Target)
      Marker(
        point: userPosition,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2980B9).withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF2980B9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),
      ),
    ];

    // 2. Hospital and Blood Bank markers
    for (final item in hospitals) {
      final h = item.hospital;
      final isSelected = selectedHospital?.hospital.id == h.id;
      final hasCritical = h.bloodStock.values.any((u) => u < 3);
      final point = ll.LatLng(h.latitude, h.longitude);

      markers.add(
        Marker(
          point: point,
          width: isSelected ? 54 : 46,
          height: isSelected ? 54 : 46,
          child: GestureDetector(
            onTap: () => onHospitalTap(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed
                    : (h.isBloodBank ? const Color(0xFF2980B9) : AppColors.surface),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : (h.isBloodBank ? Colors.white : AppColors.primaryRed),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    h.isBloodBank ? Icons.bloodtype_rounded : Icons.local_hospital_rounded,
                    color: isSelected
                        ? Colors.white
                        : (h.isBloodBank ? Colors.white : AppColors.primaryRed),
                    size: isSelected ? 26 : 22,
                  ),
                  if (hasCritical)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: userPosition,
            initialZoom: 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.blooddonation.finder',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        _buildEngineBadge('OpenStreetMap (Hospital Locator)'),
      ],
    );
  }

  Widget _buildEngineBadge(String engineName) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              engineName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
