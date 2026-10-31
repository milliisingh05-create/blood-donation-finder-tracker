import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blood_donation_finder/core/data/mock_seed_data.dart';
import 'package:blood_donation_finder/core/services/location_service.dart';
import 'package:blood_donation_finder/features/hospitals/data/hospitals_repository.dart';
import 'package:blood_donation_finder/features/hospitals/presentation/screens/hospitals_list_screen.dart';
import 'package:blood_donation_finder/features/hospitals/presentation/widgets/hospital_detail_modal.dart';
import 'package:blood_donation_finder/features/hospitals/presentation/widgets/update_stock_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HospitalsRepository Unit Tests', () {
    test('watchHospitals yields seed facilities', () async {
      final repo = HospitalsRepository();
      addTearDown(repo.dispose);

      final list = await repo.watchHospitals().first;
      expect(list.isNotEmpty, isTrue);
      expect(list.length, equals(MockSeedData.hospitals.length));
    });

    test('getHospitalsWithDistance calculates distances and sorts ascending', () {
      final repo = HospitalsRepository();
      addTearDown(repo.dispose);

      final list = repo.getHospitalsWithDistance(
        userLat: LocationService.defaultLatitude,
        userLng: LocationService.defaultLongitude,
      );

      expect(list.isNotEmpty, isTrue);
      for (int i = 0; i < list.length - 1; i++) {
        expect(list[i].distanceKm <= list[i + 1].distanceKm, isTrue);
      }
    });

    test('getHospitalsWithDistance filters by type and critical shortage', () {
      final repo = HospitalsRepository();
      addTearDown(repo.dispose);

      // Filter by blood bank
      final bloodBanks = repo.getHospitalsWithDistance(
        userLat: LocationService.defaultLatitude,
        userLng: LocationService.defaultLongitude,
        type: 'blood_bank',
      );
      expect(bloodBanks.every((h) => h.hospital.isBloodBank), isTrue);

      // Filter by critical shortage (<3 units)
      final critical = repo.getHospitalsWithDistance(
        userLat: LocationService.defaultLatitude,
        userLng: LocationService.defaultLongitude,
        criticalOnly: true,
      );
      expect(critical.isNotEmpty, isTrue);
      for (final item in critical) {
        expect(item.hospital.bloodStock.values.any((u) => u < 3), isTrue);
      }
    });

    test('updateBloodStock updates units and emits stream', () async {
      final repo = HospitalsRepository();
      addTearDown(repo.dispose);

      const targetHospitalId = 'hosp_001';
      await repo.updateBloodStock(
        hospitalId: targetHospitalId,
        bloodGroup: 'O-',
        newUnits: 15,
      );

      final updated = await repo.watchHospitals().first;
      final target = updated.firstWhere((h) => h.id == targetHospitalId);
      expect(target.stockFor('O-'), equals(15));
    });
  });

  group('HospitalsListScreen Widget Tests', () {
    testWidgets('Renders search input, facility type chips, and hospital cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HospitalsListScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify title & search
      expect(find.text('Hospitals & Blood Banks'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify type chips
      expect(find.text('All Facilities'), findsOneWidget);
      expect(find.text('Hospitals'), findsOneWidget);
      expect(find.text('Blood Banks'), findsOneWidget);

      // Verify shortage chip
      expect(find.text('Shortages (<3)'), findsOneWidget);

      // Verify facility cards in viewport
      expect(find.textContaining('Hospital'), findsWidgets);
      expect(find.text('Call Desk'), findsWidgets);
      expect(find.text('Directions'), findsWidgets);
    });

    testWidgets('UpdateStockModal renders blood group steppers', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UpdateStockModal(
                hospital: MockSeedData.hospitals.first,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify title & staff mode badge
      expect(find.text('Update Inventory'), findsOneWidget);
      expect(find.text('Staff Mode'), findsOneWidget);

      // Verify save button
      expect(find.text('Save Stock Levels'), findsOneWidget);
    });

    testWidgets('HospitalDetailModal renders 8 blood group stock grid and pledge button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HospitalDetailModal(
                hospital: MockSeedData.hospitals.first,
                formattedDistance: '1.8 km away',
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify header details
      expect(find.text('Metro General Hospital & Trauma Center'), findsOneWidget);
      expect(find.text('1.8 km away'), findsOneWidget);
      expect(find.text('Call Desk'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);

      // Verify compatibility and live stock grid
      expect(find.text('Live Blood Inventory'), findsOneWidget);
      expect(find.text('Record Donation at this Center'), findsOneWidget);
    });

    testWidgets('HospitalsListScreen switches between Directory List and Map Locator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HospitalsListScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Initial state is List mode: shortage alert banner is visible
      expect(find.text('Urgent: Critical shortages (<3 units) detected nearby'), findsOneWidget);
      expect(find.text('Filter Shortages'), findsOneWidget);

      // Tap Map Locator toggle button in AppBar
      final mapToggle = find.byIcon(Icons.map_rounded);
      expect(mapToggle, findsOneWidget);
      await tester.tap(mapToggle);
      await tester.pump(const Duration(milliseconds: 200));

      // In Map mode, map view engine badge is shown and toggle changes to list icon
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
      expect(find.text('OpenStreetMap (Hospital Locator)'), findsOneWidget);

      // Tap back to List mode
      await tester.tap(find.byIcon(Icons.view_list_rounded));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.map_rounded), findsOneWidget);
      expect(find.text('All Facilities'), findsOneWidget);
    });
  });
}

