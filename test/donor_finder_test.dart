import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blood_donation_finder/core/data/mock_seed_data.dart';
import 'package:blood_donation_finder/core/services/location_service.dart';
import 'package:blood_donation_finder/core/widgets/donor_card.dart';
import 'package:blood_donation_finder/features/donor_finder/data/donor_finder_repository.dart';
import 'package:blood_donation_finder/features/donor_finder/presentation/controllers/donor_finder_controller.dart';
import 'package:blood_donation_finder/features/donor_finder/presentation/screens/donor_finder_screen.dart';
import 'package:blood_donation_finder/features/donor_finder/presentation/widgets/app_map_view.dart';
import 'package:blood_donation_finder/features/donor_finder/presentation/widgets/staggered_donor_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService & Haversine Tests', () {
    test('calculateDistanceKm calculates realistic distances', () {
      // Distance between two points in San Francisco
      final dist = LocationService.calculateDistanceKm(
        startLatitude: 37.7749,
        startLongitude: -122.4194,
        endLatitude: 37.7885,
        endLongitude: -122.4072,
      );

      // Should be approximately 1.8 - 2.0 km
      expect(dist, greaterThan(1.0));
      expect(dist, lessThan(3.0));
    });

    test('calculateDistanceKm returns 0 for identical points', () {
      final dist = LocationService.calculateDistanceKm(
        startLatitude: 37.7749,
        startLongitude: -122.4194,
        endLatitude: 37.7749,
        endLongitude: -122.4194,
      );
      expect(dist, equals(0.0));
    });
  });

  group('DonorFinderRepository Tests', () {
    final repository = DonorFinderRepository();

    test('MockSeedData contains exactly 10 seeded demo donors', () {
      expect(MockSeedData.donors.length, equals(10));
    });

    test('watchNearbyDonors returns sorted donors within default radius', () async {
      final donors = await repository
          .watchNearbyDonors(
            userLat: LocationService.defaultLatitude,
            userLng: LocationService.defaultLongitude,
            radiusKm: 10.0,
            activeOnly: true,
          )
          .first;

      expect(donors.isNotEmpty, isTrue);

      // Verify sorted in ascending order of distance
      for (int i = 0; i < donors.length - 1; i++) {
        expect(donors[i].distanceKm <= donors[i + 1].distanceKm, isTrue);
      }

      // Verify all donors are within 10 km
      for (final d in donors) {
        expect(d.distanceKm, lessThanOrEqualTo(10.0));
        expect(d.profile.isActive, isTrue);
      }
    });

    test('watchNearbyDonors filters by blood group correctly', () async {
      final oNegDonors = await repository
          .watchNearbyDonors(
            userLat: LocationService.defaultLatitude,
            userLng: LocationService.defaultLongitude,
            radiusKm: 25.0,
            bloodGroup: 'O-',
            activeOnly: false,
          )
          .first;

      expect(oNegDonors.isNotEmpty, isTrue);
      for (final d in oNegDonors) {
        expect(d.profile.bloodGroup, equals('O-'));
      }
    });

    test('watchNearbyDonors respects activeOnly filter', () async {
      final activeOnlyDonors = await repository
          .watchNearbyDonors(
            userLat: LocationService.defaultLatitude,
            userLng: LocationService.defaultLongitude,
            radiusKm: 25.0,
            activeOnly: true,
          )
          .first;

      final allDonors = await repository
          .watchNearbyDonors(
            userLat: LocationService.defaultLatitude,
            userLng: LocationService.defaultLongitude,
            radiusKm: 25.0,
            activeOnly: false,
          )
          .first;

      expect(allDonors.length, greaterThanOrEqualTo(activeOnlyDonors.length));
      for (final d in activeOnlyDonors) {
        expect(d.profile.isActive, isTrue);
      }
    });
  });

  group('DonorFinderController Tests', () {
    test('updates filters, radius, and selection correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(donorFinderControllerProvider.notifier);

      // Verify default state
      expect(container.read(donorFinderControllerProvider).selectedRadiusKm, equals(10.0));
      expect(container.read(donorFinderControllerProvider).activeOnly, isTrue);
      expect(container.read(donorFinderControllerProvider).selectedBloodGroup, isNull);

      // Set radius
      controller.setRadius(25.0);
      expect(container.read(donorFinderControllerProvider).selectedRadiusKm, equals(25.0));

      // Set blood group
      controller.setBloodGroup('AB+');
      expect(container.read(donorFinderControllerProvider).selectedBloodGroup, equals('AB+'));

      // Toggle active only
      controller.toggleActiveOnly(false);
      expect(container.read(donorFinderControllerProvider).activeOnly, isFalse);
    });
  });

  group('DonorCard & Staggered Animation Tests', () {
    testWidgets('DonorCard displays approximate distance and privacy locked call button', (WidgetTester tester) async {
      bool callTapped = false;
      bool requestTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DonorCard(
              name: 'Elena Rostova',
              bloodGroup: 'O-',
              distanceAway: '1.4 km away',
              isActive: true,
              city: 'Mission Bay',
              totalDonations: 4,
              canCall: false, // Locked until accepted
              onCallTap: () => callTapped = true,
              onRequestTap: () => requestTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('O-'), findsOneWidget);
      expect(find.text('1.4 km away • Mission Bay'), findsOneWidget);
      expect(find.text('Request'), findsOneWidget);
      expect(find.byIcon(Icons.phone_locked_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.phone_locked_rounded));
      expect(callTapped, isTrue);

      await tester.tap(find.text('Request'));
      expect(requestTapped, isTrue);
    });

    testWidgets('StaggeredDonorCard animates and renders content', (WidgetTester tester) async {
      final sample = DiscoveredDonor(
        profile: MockSeedData.donors.first,
        distanceKm: 1.2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredDonorCard(
              donor: sample,
              index: 0,
              canCall: false,
              onCallTap: () {},
              onRequestTap: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(sample.profile.name), findsOneWidget);
      expect(find.text(sample.profile.bloodGroup), findsWidgets);
    });

    testWidgets('AppMapView renders fallback OpenStreetMap engine badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppMapView(
              centerLat: 37.7749,
              centerLng: -122.4194,
              donors: [
                DiscoveredDonor(profile: MockSeedData.donors.first, distanceKm: 1.0),
              ],
              onDonorTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('OpenStreetMap Live'), findsOneWidget);
    });
  });

  group('DonorFinderScreen Widget Tests', () {
    testWidgets('Renders top filter bar, radius pills, and donor sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DonorFinderScreen(),
          ),
        ),
      );

      // Pump initial frame and staggered sheet animation
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify title
      expect(find.text('Find Nearby Donors'), findsOneWidget);

      // Verify radius pills
      expect(find.text('1 km'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);
      expect(find.text('25 km'), findsOneWidget);

      // Verify blood group chips
      expect(find.text('All Groups'), findsWidgets);
      expect(find.text('O-'), findsWidgets);
      expect(find.text('O+'), findsWidgets);
      expect(find.text('A+'), findsWidgets);

      // Verify Request Blood action exists
      expect(find.text('Request Blood'), findsWidgets);
    });
  });
}
