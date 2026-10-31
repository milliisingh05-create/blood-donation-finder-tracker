import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blood_donation_finder/features/notifications/data/notifications_repository.dart';
import 'package:blood_donation_finder/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:blood_donation_finder/features/requests/data/requests_repository.dart';
import 'package:blood_donation_finder/features/requests/domain/models/donation_request.dart';
import 'package:blood_donation_finder/features/requests/presentation/screens/create_request_screen.dart';
import 'package:blood_donation_finder/features/requests/presentation/screens/requests_inbox_screen.dart';
import 'package:blood_donation_finder/features/requests/presentation/screens/request_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RequestsRepository Unit Tests', () {
    final repo = RequestsRepository();

    test('createRequest adds request and returns compatible donors count', () async {
      final req = DonationRequest(
        id: 'test_req_001',
        requesterId: 'test_user',
        bloodGroup: 'O-',
        units: 2,
        urgency: 'critical',
        hospitalName: 'Metro General Hospital',
        latitude: 37.77,
        longitude: -122.41,
        geohash: '9q8yy',
        contactNumber: '+1 415-555-0101',
        createdAt: DateTime.now(),
      );

      final matchCount = await repo.createRequest(req);
      expect(matchCount, greaterThan(0));

      final openRequests = await repo.watchOpenRequests().first;
      expect(openRequests.any((r) => r.id == 'test_req_001'), isTrue);
    });

    test('acceptRequest updates acceptedBy and status', () async {
      await repo.acceptRequest('test_req_001', 'test_donor_99');

      final req = repo.getRequestByIdSync('test_req_001');
      expect(req, isNotNull);
      expect(req!.isAccepted, isTrue);
      expect(req.acceptedBy.contains('test_donor_99'), isTrue);
    });

    test('fulfillRequest updates status to fulfilled', () async {
      await repo.fulfillRequest('test_req_001');

      final req = repo.getRequestByIdSync('test_req_001');
      expect(req, isNotNull);
      expect(req!.isFulfilled, isTrue);
    });

    test('cancelRequest updates status to cancelled', () async {
      await repo.cancelRequest('test_req_001');

      final req = repo.getRequestByIdSync('test_req_001');
      expect(req, isNotNull);
      expect(req!.isCancelled, isTrue);
    });

    test('declineRequest hides request from open requests', () async {
      final req = repo.getRequestByIdSync('req_002');
      expect(req, isNotNull);

      await repo.declineRequest('req_002', 'current_user');

      final openRequests = await repo.watchOpenRequests().first;
      expect(openRequests.any((r) => r.id == 'req_002'), isFalse);
    });

    test('watchReceivedRequests excludes own requests and declined requests', () async {
      final received = await repo.watchReceivedRequests('user_patient_01').first;
      expect(received.any((r) => r.requesterId == 'user_patient_01'), isFalse);
    });
  });

  group('NotificationsRepository Unit Tests', () {
    final repo = NotificationsRepository();

    test('watchNotifications emits demo alerts with unread flags', () async {
      final notifs = await repo.watchNotifications('current_user').first;
      expect(notifs.isNotEmpty, isTrue);
      expect(notifs.any((n) => !n.read), isTrue);
    });

    test('markAllAsRead sets all notification flags to read', () async {
      await repo.markAllAsRead();

      final notifs = await repo.watchNotifications('current_user').first;
      expect(notifs.every((n) => n.read), isTrue);
    });
  });

  group('CreateRequestScreen Widget Tests', () {
    testWidgets('Renders all request form fields, units stepper, and submit button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateRequestScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify header title
      expect(find.text('Request Blood'), findsOneWidget);

      // Verify blood group chips
      expect(find.text('O+'), findsWidgets);
      expect(find.text('O-'), findsWidgets);
      expect(find.text('A+'), findsWidgets);

      // Verify Urgency options
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);

      // Verify submit button
      expect(find.text('Submit Blood Request'), findsOneWidget);
    });
  });

  group('RequestsInboxScreen Widget Tests', () {
    testWidgets('Renders Received & Sent tabs and FAB', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RequestsInboxScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify title & tabs
      expect(find.text('Blood Requests'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);

      // Verify filter chip and FAB
      expect(find.text('Critical Only'), findsOneWidget);
      expect(find.text('New Request'), findsOneWidget);
    });
  });

  group('RequestDetailScreen Widget Tests', () {
    testWidgets('Renders details, hospital, urgency, and privacy gate for open request', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RequestDetailScreen(requestId: 'req_001'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Request Details'), findsOneWidget);
      expect(find.text('CRITICAL EMERGENCY REQUEST'), findsOneWidget);
      expect(find.text('Metro General Hospital & Trauma Center'), findsOneWidget);
      expect(find.text('Privacy Protection Gate'), findsOneWidget);
      expect(find.text('Accept Request'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });
  });

  group('NotificationsScreen Widget Tests', () {
    testWidgets('Renders notification center and filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify title
      expect(find.text('Notifications'), findsOneWidget);

      // Verify filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Emergency SOS'), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);
    });

    testWidgets('Tapping simulate push notification icon adds alert and shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      final alertBtn = find.byIcon(Icons.add_alert_rounded);
      expect(alertBtn, findsOneWidget);

      await tester.tap(alertBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Incoming SOS Alert: Critical O- needed at Metro General Hospital'), findsOneWidget);
      expect(find.text('VIEW'), findsOneWidget);
    });
  });
}
