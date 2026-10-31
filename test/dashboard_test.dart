import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blood_donation_finder/core/data/mock_seed_data.dart';
import 'package:blood_donation_finder/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:blood_donation_finder/features/dashboard/presentation/widgets/animated_eligibility_card.dart';
import 'package:blood_donation_finder/features/dashboard/presentation/widgets/animated_stat_card.dart';
import 'package:blood_donation_finder/features/dashboard/presentation/widgets/staggered_request_card.dart';
import 'package:blood_donation_finder/features/profile/presentation/controllers/profile_controller.dart';
import 'package:blood_donation_finder/features/requests/domain/models/donation_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Donor Dashboard Tests', () {
    testWidgets('AnimatedStatCard renders title, icon, and animates count-up', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStatCard(
              title: 'Total Donations',
              count: 8,
              icon: Icons.water_drop_rounded,
            ),
          ),
        ),
      );

      expect(find.text('Total Donations'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);

      // Advance animation
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('AnimatedEligibilityCard renders READY state when eligible with 90-day interval', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEligibilityCard(
              isEligible: true,
              daysUntilEligible: 0,
            ),
          ),
        ),
      );

      expect(find.text('READY'), findsOneWidget);
      expect(find.text('Eligible Now'), findsOneWidget);
      expect(find.text('90d interval met'), findsOneWidget);
    });

    testWidgets('AnimatedEligibilityCard renders WAIT state and countdown when in recovery', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEligibilityCard(
              isEligible: false,
              daysUntilEligible: 45,
            ),
          ),
        ),
      );

      // Advance animation to end of tween
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('WAIT'), findsOneWidget);
      expect(find.text('In 45 days'), findsOneWidget);
      expect(find.text('90d recovery interval'), findsOneWidget);
    });

    testWidgets('StaggeredRequestCard renders request details and action button', (WidgetTester tester) async {
      final req = DonationRequest(
        id: 'test_req_1',
        requesterId: 'u1',
        requesterName: 'Sarah Jenkins',
        bloodGroup: 'O+',
        units: 2,
        urgency: 'critical',
        hospitalName: 'General Trauma Hospital',
        latitude: 37.77,
        longitude: -122.41,
        geohash: '9q8yy',
        contactNumber: '555-0100',
        createdAt: DateTime.now(),
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredRequestCard(
              request: req,
              index: 0,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('General Trauma Hospital'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('2 unit(s) • Needed by Sarah Jenkins'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);

      await tester.tap(find.text('View'));
      expect(tapped, isTrue);
    });

    testWidgets('DashboardScreen renders greeting, blood group, SOS banner, and actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      // Pump initial render frame and staggered animation
      await tester.pump(const Duration(milliseconds: 1000));

      final sample = MockSeedData.donors.first;
      final firstName = sample.name.split(' ').first;

      // Verify personalized greeting and blood group
      expect(find.text('Hello, $firstName 👋'), findsOneWidget);
      expect(find.text(sample.bloodGroup), findsWidgets);

      // Verify Emergency SOS broadcast banner
      expect(find.text('EMERGENCY SOS BROADCAST'), findsOneWidget);

      // Verify Quick Action titles
      expect(find.text('Find Donors'), findsOneWidget);
      expect(find.text('Emergency SOS'), findsOneWidget);
      expect(find.text('My Donations'), findsOneWidget);
      expect(find.text('Hospitals & Banks'), findsOneWidget);
    });

    test('Availability toggle updates the data source instantly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialProfile = container.read(profileControllerProvider).value;
      expect(initialProfile, isNotNull);
      final initialActive = initialProfile!.isActive;

      await container.read(profileControllerProvider.notifier).toggleAvailability();
      final updatedProfile = container.read(profileControllerProvider).value;

      expect(updatedProfile, isNotNull);
      expect(updatedProfile!.isActive, equals(!initialActive));
    });
  });
}
