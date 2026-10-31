import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blood_donation_finder/core/widgets/digital_donor_card.dart';
import 'package:blood_donation_finder/features/donations/data/donations_repository.dart';
import 'package:blood_donation_finder/features/donations/domain/models/donation_record.dart';
import 'package:blood_donation_finder/features/donations/presentation/controllers/donations_controller.dart';
import 'package:blood_donation_finder/features/donations/presentation/screens/donations_history_screen.dart';
import 'package:blood_donation_finder/features/donations/presentation/screens/record_donation_screen.dart';
import 'package:blood_donation_finder/features/notifications/data/notifications_repository.dart';
import 'package:blood_donation_finder/features/profile/data/profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DonationsRepository Medical Interval & Math Tests', () {
    test('calculateDaysRemaining correctly computes 90-day cooldown', () {
      // Never donated -> 0 days remaining (immediately eligible)
      expect(DonationsRepository.calculateDaysRemaining(null), equals(0));

      // Donated today -> 90 days remaining
      final today = DateTime.now();
      expect(DonationsRepository.calculateDaysRemaining(today), inInclusiveRange(89, 90));

      // Donated 45 days ago -> 45 days remaining
      final fortyFiveDaysAgo = DateTime.now().subtract(const Duration(days: 45));
      expect(DonationsRepository.calculateDaysRemaining(fortyFiveDaysAgo), inInclusiveRange(44, 46));

      // Donated 91 days ago -> 0 days remaining (cooldown expired)
      final ninetyOneDaysAgo = DateTime.now().subtract(const Duration(days: 91));
      expect(DonationsRepository.calculateDaysRemaining(ninetyOneDaysAgo), equals(0));
    });

    test('calculateEligibilityProgress accurately scales 0.0 to 1.0', () {
      // Never donated -> 1.0 (100% eligible)
      expect(DonationsRepository.calculateEligibilityProgress(null), equals(1.0));

      // Donated today -> ~0.0
      final today = DateTime.now();
      expect(DonationsRepository.calculateEligibilityProgress(today), inInclusiveRange(0.0, 0.02));

      // Donated 45 days ago -> ~0.50
      final halfWay = DateTime.now().subtract(const Duration(days: 45));
      expect(DonationsRepository.calculateEligibilityProgress(halfWay), inInclusiveRange(0.48, 0.52));

      // Donated 100 days ago -> clamped to 1.0
      final expired = DateTime.now().subtract(const Duration(days: 100));
      expect(DonationsRepository.calculateEligibilityProgress(expired), equals(1.0));
    });

    test('watchUserDonations returns seed donation list', () async {
      final repo = DonationsRepository();
      addTearDown(repo.dispose);

      final list = await repo.watchUserDonations('current_user').first;
      expect(list.isNotEmpty, isTrue);
      expect(list.first.hospitalName, isNotEmpty);
      expect(list.first.units, greaterThan(0));
    });

    test('recordDonation updates profile badges, points and creates notification', () async {
      final profileRepo = ProfileRepository();
      final notifsRepo = NotificationsRepository();
      final repo = DonationsRepository(
        profileRepository: profileRepo,
        notificationsRepository: notifsRepo,
      );
      addTearDown(repo.dispose);
      addTearDown(notifsRepo.dispose);

      final initialProfile = profileRepo.getCachedProfile('user_test_1');
      final initialPoints = initialProfile.points;

      final record = DonationRecord(
        id: 'rec_test_123',
        donorId: 'user_test_1',
        donorName: 'Test Donor',
        hospitalId: 'hosp_001',
        hospitalName: 'Apollo Speciality Hospital',
        bloodGroup: 'O+',
        units: 2,
        date: DateTime.now(),
        verified: true,
        pointsEarned: 200,
      );

      await repo.recordDonation(record);

      // Verify donation prepended
      final donations = await repo.watchUserDonations('user_test_1').first;
      expect(donations.first.id, equals('rec_test_123'));
      expect(donations.first.pointsEarned, equals(200));

      // Verify points added to profile
      final updatedProfile = profileRepo.getCachedProfile('user_test_1');
      expect(updatedProfile.points, equals(initialPoints + 200));
      expect(updatedProfile.badges.contains('First Drop'), isTrue);

      // Verify celebration notification dispatched
      final notifs = await notifsRepo.watchNotifications('user_test_1').first;
      expect(notifs.any((n) => n.title.contains('+200 Points Earned')), isTrue);
    });
  });

  group('DonationStats Domain Model Tests', () {
    test('DonationStats calculates liters and lives saved correctly', () {
      const stats = DonationStats(
        totalDonations: 4,
        totalUnits: 5,
        litersDonated: 5 * 0.45,
        estimatedLivesSaved: 5 * 3,
        totalPoints: 500,
        daysUntilEligible: 0,
        eligibilityProgress: 1.0,
      );

      expect(stats.totalDonations, equals(4));
      expect(stats.totalUnits, equals(5));
      expect(stats.litersDonated, closeTo(2.25, 0.01));
      expect(stats.estimatedLivesSaved, equals(15));
      expect(stats.isEligibleNow, isTrue);
    });

    test('DonationStats handles active waiting period', () {
      const stats = DonationStats(
        totalDonations: 1,
        totalUnits: 1,
        litersDonated: 0.45,
        estimatedLivesSaved: 3,
        totalPoints: 100,
        daysUntilEligible: 42,
        eligibilityProgress: 0.53,
      );

      expect(stats.isEligibleNow, isFalse);
      expect(stats.daysUntilEligible, equals(42));
    });
  });

  group('Donations History & Record Widget Tests', () {
    testWidgets('DonationsHistoryScreen renders hero stats, eligibility, badges and history', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DonationsHistoryScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify App Bar
      expect(find.text('Donation Tracker & History'), findsOneWidget);

      // 2. Verify Hero Impact Stats
      expect(find.text('Lives Saved'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Hero Points'), findsOneWidget);

      // 3. Verify Milestone Badges section
      expect(find.text('Milestone Achievements'), findsOneWidget);
      expect(find.text('First Drop'), findsOneWidget);
      expect(find.text('Life Saver x3'), findsOneWidget);
      expect(find.text('Golden Heart'), findsOneWidget);

      // 4. Verify Record Donation FAB
      expect(find.text('Record Donation'), findsOneWidget);
      expect(find.byIcon(Icons.add_task_rounded), findsOneWidget);
    });

    testWidgets('RecordDonationScreen allows filling form and shows celebration modal', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecordDonationScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify screen title
      expect(find.text('Record Donation'), findsOneWidget);

      // 2. Verify form sections
      expect(find.text('Donation Center / Hospital'), findsOneWidget);
      expect(find.text('Blood Group Donated'), findsOneWidget);
      expect(find.text('Units Donated'), findsOneWidget);
      expect(find.text('Donation Date'), findsOneWidget);
      expect(find.text('Clinical Vitals (Optional)'), findsOneWidget);

      // 3. Verify units selection interaction
      final twoUnitsOption = find.text('2 Units (~900 mL)');
      expect(twoUnitsOption, findsOneWidget);
      await tester.tap(twoUnitsOption);
      await tester.pump();

      // 4. Verify Submit Button reflects updated units & points
      final submitButton = find.text('Record Donation & Claim +200 Pts');
      expect(submitButton, findsOneWidget);

      // Scroll to submit button and tap
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Donation Verified!'), findsOneWidget);
      expect(find.textContaining('Up to 6 lives saved!'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('View Timeline'), findsOneWidget);
    });

    testWidgets('DigitalDonorCard renders donor identity and toggles QR check-in mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DigitalDonorCard(
                donorName: 'Marcus Chen',
                bloodGroup: 'O+',
                donorId: 'DONOR-7892',
                totalDonations: 4,
                city: 'San Francisco, CA',
                isActive: true,
                memberSince: '2024',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify header and donor details
      expect(find.text('DIGITAL DONOR PASS'), findsOneWidget);
      expect(find.text('ACTIVE DONOR'), findsOneWidget);
      expect(find.text('Marcus Chen'), findsOneWidget);
      expect(find.text('ID: DONOR-7892'), findsOneWidget);
      expect(find.text('4 Completed'), findsOneWidget);
      expect(find.text('National Blood Registry Verified'), findsOneWidget);

      // Tap 'Scan QR' button to flip to QR check-in view
      final scanQrButton = find.text('Scan QR');
      expect(scanQrButton, findsOneWidget);
      await tester.tap(scanQrButton);
      await tester.pump();

      // Verify QR view is visible
      expect(find.text('Express Hospital Check-In'), findsOneWidget);
      expect(find.text('Scan at hospital reception or blood drive unit'), findsOneWidget);
      expect(find.text('Show Details'), findsOneWidget);

      // Tap 'Show Details' to flip back
      await tester.tap(find.text('Show Details'));
      await tester.pump();
      expect(find.text('Marcus Chen'), findsOneWidget);
    });

    testWidgets('DonationsHistoryScreen interacts with digital pass, milestone perks, and filters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DonationsHistoryScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // 1. Digital Donor Pass Toggle
      expect(find.text('Digital Donor Pass & QR'), findsOneWidget);
      final viewPassButton = find.text('View Pass');
      expect(viewPassButton, findsOneWidget);
      await tester.tap(viewPassButton);
      await tester.pump();

      // Now DigitalDonorCard should be displayed inside history screen
      expect(find.text('DIGITAL DONOR PASS'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);

      // Collapse pass
      await tester.tap(find.text('Hide'));
      await tester.pump();
      expect(find.text('DIGITAL DONOR PASS'), findsNothing);

      // 2. Tap milestone badge to open perks modal
      final milestoneBadge = find.text('First Drop');
      expect(milestoneBadge, findsOneWidget);
      await tester.tap(milestoneBadge);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Milestone Privilege & Perks'), findsOneWidget);
      final gotItFinder = find.text('Got it');
      expect(gotItFinder, findsOneWidget);
      await tester.ensureVisible(gotItFinder);
      await tester.pumpAndSettle();
      await tester.tap(gotItFinder);
      await tester.pumpAndSettle();

      // 3. Filter chips interaction
      expect(find.widgetWithText(ChoiceChip, 'All Records'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Whole Blood'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Platelets'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Plasma'), findsOneWidget);

      // Switch filter to Whole Blood
      final wholeBloodChip = find.widgetWithText(ChoiceChip, 'Whole Blood');
      await tester.ensureVisible(wholeBloodChip);
      await tester.pumpAndSettle();
      await tester.tap(wholeBloodChip);
      await tester.pumpAndSettle();

      // Verify Whole Blood chip is selected and timeline reflects it
      expect(find.text('Whole Blood'), findsWidgets);
    });

    testWidgets('RecordDonationScreen calculates custom points and recovery for Platelets', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RecordDonationScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Tap Platelets option
      final plateletsChip = find.text('Platelets');
      expect(plateletsChip, findsOneWidget);
      await tester.tap(plateletsChip);
      await tester.pump();

      // Verify recovery badge says 14-Day Recovery
      expect(find.text('14-Day Recovery'), findsOneWidget);

      // Verify submit button shows +150 Pts
      expect(find.text('Record Donation & Claim +150 Pts'), findsOneWidget);
    });
  });
}

