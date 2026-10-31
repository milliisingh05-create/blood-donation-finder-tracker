import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blood_donation_finder/core/data/mock_seed_data.dart';
import 'package:blood_donation_finder/features/auth/data/auth_repository.dart';
import 'package:blood_donation_finder/features/auth/presentation/screens/phone_auth_screen.dart';
import 'package:blood_donation_finder/features/hospitals/presentation/screens/hospitals_list_screen.dart';
import 'package:blood_donation_finder/features/leaderboard/data/leaderboard_repository.dart';
import 'package:blood_donation_finder/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:blood_donation_finder/core/widgets/app_error_widget.dart';
import 'package:blood_donation_finder/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:blood_donation_finder/features/notifications/data/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 3: PushNotificationService Tests', () {
    test('PushNotificationService initializes safely and can trigger local notifications', () async {
      final service = PushNotificationService();
      await service.initialize();
      expect(service.isInitialized, isTrue);

      // Should execute without throwing on any platform
      await expectLater(
        service.showLocalNotification(
          title: '🚨 Emergency Test Alert',
          body: 'Testing emergency push notification channel',
          isEmergency: true,
        ),
        completes,
      );
    });
  });

  group('Step 3: Phone Authentication Flow Tests', () {
    test('AuthRepository verifyPhoneNumber dispatches verificationId in offline/dev mode', () async {
      final repo = AuthRepository();
      String? sentVid;
      String? errorReceived;

      await repo.verifyPhoneNumber(
        phoneNumber: '+1 415-555-0199',
        onCodeSent: (vid, token) => sentVid = vid,
        onError: (err) => errorReceived = err,
      );

      expect(sentVid, isNotNull);
      expect(sentVid!.contains('offline_vid'), isTrue);
      expect(errorReceived, isNull);
    });

    test('AuthRepository signInWithPhoneOtp validates 6-digit code', () async {
      final repo = AuthRepository();

      // Valid 6-digit code
      final user = await repo.signInWithPhoneOtp(
        verificationId: 'offline_vid_test',
        smsCode: '123456',
        phoneNumber: '+1 415-555-0199',
      );
      expect(user.displayName, equals('Phone Donor'));
      expect(user.phoneNumber, equals('+1 415-555-0199'));

      // Invalid short code throws error
      expect(
        () => repo.signInWithPhoneOtp(
          verificationId: 'offline_vid_test',
          smsCode: '123',
          phoneNumber: '+1 415-555-0199',
        ),
        throwsA(isA<String>()),
      );
    });

    testWidgets('PhoneAuthScreen sends OTP and completes phone sign-in', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhoneAuthScreen(),
          ),
        ),
      );

      // Initial state displays Phone Verification header
      expect(find.text('Phone Verification'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);

      // Tap Send Verification Code
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump(const Duration(milliseconds: 800));

      // Enters OTP verification mode
      expect(find.text('Enter 6-Digit Code'), findsOneWidget);
      expect(find.text('Verify & Sign In'), findsOneWidget);

      // Enter 6-digit code and verify
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.text('Verify & Sign In'));
      await tester.pump(const Duration(milliseconds: 400));
    });
  });

  group('Step 3: Staff Role Enforcement Tests', () {
    test('UserProfile role defaults to donor and evaluates isStaffOrAdmin correctly', () {
      final donor = MockSeedData.donors.first;
      expect(donor.role, equals('donor'));
      expect(donor.isStaffOrAdmin, isFalse);

      final staff = donor.copyWith(role: 'staff');
      expect(staff.isStaffOrAdmin, isTrue);

      final admin = donor.copyWith(role: 'admin');
      expect(admin.isStaffOrAdmin, isTrue);

      final hospital = donor.copyWith(role: 'hospital');
      expect(hospital.isStaffOrAdmin, isTrue);
    });

    testWidgets('HospitalsListScreen guards update stock modal behind staff authorization', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HospitalsListScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Find edit stock icon on hospital card
      final editIcon = find.byIcon(Icons.edit_note_rounded).first;
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Because current profile is donor, Staff Access Only dialog must appear
      expect(find.text('Staff Access Only'), findsOneWidget);
      expect(find.text('Authorize as Staff'), findsOneWidget);

      // Tap Authorize as Staff
      await tester.tap(find.text('Authorize as Staff'));
      await tester.pumpAndSettle();

      // Now UpdateStockModal should open
      expect(find.text('Update Inventory'), findsOneWidget);
      expect(find.text('Staff Mode'), findsOneWidget);
    });
  });

  group('Step 3: Leaderboard & Community Rankings Tests', () {
    test('LeaderboardRepository sorts donors by points descending', () async {
      final repo = LeaderboardRepository();
      final donors = await repo.watchLeaderboard(category: 'all').first;

      expect(donors.isNotEmpty, isTrue);
      for (int i = 0; i < donors.length - 1; i++) {
        expect(donors[i].points >= donors[i + 1].points, isTrue);
      }
    });

    test('LeaderboardRepository filters by universal category (O-)', () async {
      final repo = LeaderboardRepository();
      final universalDonors = await repo.watchLeaderboard(category: 'universal').first;

      expect(universalDonors.isNotEmpty, isTrue);
      for (final donor in universalDonors) {
        expect(donor.bloodGroup, equals('O-'));
      }
    });

    testWidgets('LeaderboardScreen renders top podium and community rankings list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LeaderboardScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Header and podium
      expect(find.text('Donor Leaderboard'), findsOneWidget);
      expect(find.text('Top Life Savers'), findsOneWidget);
      expect(find.text('Community Rankings'), findsOneWidget);

      // Category filters
      expect(find.text('All Donors'), findsOneWidget);
      expect(find.text('Universal Heroes (O-)'), findsOneWidget);

      // Tap Universal filter
      await tester.tap(find.text('Universal Heroes (O-)'));
      await tester.pump(const Duration(milliseconds: 300));

      // Check footer
      expect(find.textContaining('Your Community Rank'), findsOneWidget);
    });
  });

  group('Step 4: Production Hardening & Error Boundary Tests', () {
    testWidgets('AppErrorWidget renders graceful error screen with recovery button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppErrorWidget(
            details: FlutterErrorDetails(
              exception: Exception('Simulated visual rendering error'),
            ),
          ),
        ),
      );

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.textContaining('Your health records and critical donation requests remain completely secure'), findsOneWidget);
      expect(find.text('Reload Screen'), findsOneWidget);
    });

    testWidgets('EditProfileScreen renders fields and validates clinical weight eligibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditProfileScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Find weight field and enter ineligible weight (<45 kg)
      final weightField = find.widgetWithText(TextFormField, 'e.g. 68');
      expect(weightField, findsOneWidget);
      await tester.enterText(weightField, '35');

      // Scroll and tap Save Changes
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Should show clinical eligibility warning
      expect(find.text('Minimum 45 kg required for blood donation eligibility'), findsOneWidget);
    });
  });
}
