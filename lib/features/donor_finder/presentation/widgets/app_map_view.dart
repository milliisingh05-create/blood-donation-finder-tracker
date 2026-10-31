import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/donor_finder_repository.dart';

/// Interactive dual-engine map view.
/// Renders Google Maps if an API key is provided, and gracefully falls back to
/// FlutterMap + OpenStreetMap if there is no Maps API key.
class AppMapView extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final List<DiscoveredDonor> donors;
  final DiscoveredDonor? selectedDonor;
  final ValueChanged<DiscoveredDonor> onDonorTap;

  const AppMapView({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.donors,
    this.selectedDonor,
    required this.onDonorTap,
  });

  @override
  Widget build(BuildContext context) {
    if (AppConfig.hasGoogleMapsKey) {
      return _buildGoogleMap(context);
    }
    // Default fallback to free OpenStreetMap
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
      ...donors.map((donor) {
        return gmaps.Marker(
          markerId: gmaps.MarkerId(donor.profile.uid),
          position: gmaps.LatLng(donor.profile.latitude, donor.profile.longitude),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
          infoWindow: gmaps.InfoWindow(
            title: '${donor.profile.bloodGroup} Donor (${donor.formattedDistance})',
            snippet: donor.profile.name,
          ),
          onTap: () => onDonorTap(donor),
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

    // Build markers for all discovered donors
    final List<Marker> markers = [
      // 1. User Live Location Marker (Blue Target Pin)
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
              width: 20,
              height: 20,
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

    // 2. Donor Teardrop Markers with Blood Group Label (Red Pins)
    for (final donor in donors) {
      final isSelected = selectedDonor?.profile.uid == donor.profile.uid;
      final donorPoint = ll.LatLng(donor.profile.latitude, donor.profile.longitude);

      markers.add(
        Marker(
          point: donorPoint,
          width: isSelected ? 52 : 44,
          height: isSelected ? 52 : 44,
          child: GestureDetector(
            onTap: () => onDonorTap(donor),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : AppColors.primaryRed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : AppColors.primaryDark,
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  donor.profile.bloodGroup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
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
            minZoom: 4.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.blooddonation.tracker',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        _buildEngineBadge(AppConfig.hasGoogleMapsKey ? 'Google Maps' : 'OpenStreetMap Live'),
      ],
    );
  }

  Widget _buildEngineBadge(String label) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 13, color: AppColors.primaryRed),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
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
