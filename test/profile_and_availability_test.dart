import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blood_donation_finder/core/data/mock_seed_data.dart';
import 'package:blood_donation_finder/features/profile/presentation/controllers/profile_controller.dart';
import 'package:blood_donation_finder/features/profile/presentation/screens/profile_screen.dart';
import 'package:blood_donation_finder/features/profile/presentation/widgets/animated_availability_toggle.dart';
import 'package:blood_donation_finder/features/profile/presentation/widgets/eligibility_indicator_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Donor Profile & Availability Tests', () {
    testWidgets('AnimatedAvailabilityToggle displays active state and triggers callback', (WidgetTester tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedAvailabilityToggle(
              isActive: true,
              onToggle: (val) => toggled = val,
            ),
          ),
        ),
      );

      expect(find.text('AVAILABLE (ACTIVE)'), findsOneWidget);
      await tester.tap(find.byType(AnimatedAvailabilityToggle));
      await tester.pump();

      expect(toggled, isFalse);
    });

    testWidgets('EligibilityIndicatorCard displays ELIGIBLE NOW when 90+ days elapsed', (WidgetTester tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 100));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EligibilityIndicatorCard(
              lastDonationDate: pastDate,
              isEligible: true,
              daysUntilEligible: 0,
            ),
          ),
        ),
      );

      expect(find.text('ELIGIBLE NOW'), findsOneWidget);
      expect(find.text('Ready to Save Lives'), findsOneWidget);
    });

    testWidgets('EligibilityIndicatorCard displays countdown when donor is in recovery', (WidgetTester tester) async {
      final recentDate = DateTime.now().subtract(const Duration(days: 40));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EligibilityIndicatorCard(
              lastDonationDate: recentDate,
              isEligible: false,
              daysUntilEligible: 50,
            ),
          ),
        ),
      );

      expect(find.text('WAIT PERIOD'), findsOneWidget);
      expect(find.text('Eligible in 50 days'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders donor name, blood group and badges', (WidgetTester tester) async {
      final sample = MockSeedData.donors.first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(() {
              final notifier = ProfileController();
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      // Wait for initial profile data load
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(sample.name), findsOneWidget);
      expect(find.text(sample.bloodGroup), findsOneWidget);
      expect(find.text('Points Earned'), findsOneWidget);
      expect(find.text('Community Badges'), findsOneWidget);
    });

    test('ProfileController toggleAvailability changes state immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));

      final initial = container.read(profileControllerProvider).value!;
      final initialActive = initial.isActive;

      await container.read(profileControllerProvider.notifier).toggleAvailability();
      final updated = container.read(profileControllerProvider).value!;

      expect(updated.isActive, !initialActive);
    });
  });
}
