import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blood_donation_finder/features/sos/data/sos_repository.dart';
import 'package:blood_donation_finder/features/sos/presentation/screens/sos_screen.dart';
import 'package:blood_donation_finder/features/sos/presentation/widgets/expanding_radar_visualizer.dart';
import 'package:blood_donation_finder/features/sos/presentation/widgets/hold_to_confirm_sos_button.dart';
import 'package:blood_donation_finder/features/sos/presentation/widgets/responder_coordination_sheet.dart';
import 'package:blood_donation_finder/features/sos/presentation/controllers/sos_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SosRepository Unit Tests', () {
    test('startBroadcast sets up expanding broadcast and calculates notified donors', () async {
      final repo = SosRepository();
      addTearDown(repo.dispose);

      final broadcast = await repo.startBroadcast(
        bloodGroup: 'O-',
        hospitalName: 'Metro General Hospital',
        contactNumber: '+1 415-555-9911',
      );

      expect(broadcast.isBroadcasting, isTrue);
      expect(broadcast.radiusKm, equals(5.0));
      expect(broadcast.notifiedCount, greaterThan(0));
      expect(broadcast.acceptedCount, equals(0));

      // Simulate donor acceptance
      repo.simulateDonorAcceptance();
      final updated = await repo.watchActiveBroadcast().first;
      expect(updated?.acceptedCount, equals(1));
      expect(updated?.responders.length, equals(1));

      // Resolve broadcast
      await repo.resolveBroadcast(broadcast.id);
      final resolved = await repo.watchActiveBroadcast().first;
      expect(resolved?.isResolved, isTrue);
    });

    test('updateResponderStatus advances responder milestone and adds timeline log', () async {
      final repo = SosRepository();
      addTearDown(repo.dispose);

      await repo.startBroadcast(
        bloodGroup: 'O+',
        hospitalName: 'Metro General Hospital',
        contactNumber: '+1 415-555-9911',
      );

      repo.simulateDonorAcceptance();
      final b1 = await repo.watchActiveBroadcast().first;
      expect(b1?.responders.isNotEmpty, isTrue);
      final responderId = b1!.responders.first.id;
      expect(b1.responders.first.status, equals('en_route'));

      // Advance to arrived
      repo.updateResponderStatus(responderId, 'arrived');
      final b2 = await repo.watchActiveBroadcast().first;
      expect(b2?.responders.first.status, equals('arrived'));
      expect(b2?.responders.first.hasArrived, isTrue);

      // Advance to drawing
      repo.updateResponderStatus(responderId, 'drawing');
      final b3 = await repo.watchActiveBroadcast().first;
      expect(b3?.responders.first.status, equals('drawing'));
      expect(b3?.responders.first.isDrawing, isTrue);

      // Advance to completed
      repo.updateResponderStatus(responderId, 'completed');
      final b4 = await repo.watchActiveBroadcast().first;
      expect(b4?.responders.first.status, equals('completed'));
      expect(b4?.responders.first.isCompleted, isTrue);

      // Verify timeline logs recorded milestone
      expect(b4?.timelineLogs.any((log) => log.contains('Donation Completed')), isTrue);
    });

    test('cancelBroadcast updates status with reason', () async {
      final repo = SosRepository();
      addTearDown(repo.dispose);

      final broadcast = await repo.startBroadcast(
        bloodGroup: 'B+',
        hospitalName: 'Pacific Regional Blood Bank',
        contactNumber: '+1 415-555-0000',
      );

      await repo.cancelBroadcast(broadcast.id, reason: 'Patient transferred');
      final cancelled = await repo.watchActiveBroadcast().first;
      expect(cancelled?.status, equals('cancelled'));
    });
  });

  group('SosScreen & Responder Coordination Widget Tests', () {
    testWidgets('Renders pre-broadcast trigger view with blood chips and hold button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SosScreen(),
          ),
        ),
      );

      // Pump initial frame without pumpAndSettle due to LifeLineBackground continuous animation
      await tester.pump(const Duration(milliseconds: 200));

      // Verify title & red alert badge
      expect(find.text('Emergency SOS Broadcast'), findsOneWidget);
      expect(find.text('HIGH-PRIORITY RED ALERT'), findsOneWidget);
      expect(find.text('Emergency Donor SOS'), findsOneWidget);

      // Verify blood group chips
      expect(find.text('O-'), findsWidgets);
      expect(find.text('O+'), findsWidgets);

      // Verify Hold to confirm button
      expect(find.byType(HoldToConfirmSosButton), findsOneWidget);
      expect(find.text('HOLD FOR SOS'), findsOneWidget);
    });

    testWidgets('ExpandingRadarVisualizer renders concentric rings and central hospital pin', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandingRadarVisualizer(
              currentRadiusKm: 10.0,
              notifiedCount: 8,
              acceptedCount: 2,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify static ring labels
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);
      expect(find.text('25 km'), findsOneWidget);

      // Verify central medical hospital icon
      expect(find.byIcon(Icons.local_hospital_rounded), findsOneWidget);
    });

    testWidgets('Renders live broadcast view with responders, reserve check, and timeline logs', (WidgetTester tester) async {
      final repo = SosRepository();
      addTearDown(repo.dispose);

      await repo.startBroadcast(
        bloodGroup: 'O-',
        hospitalName: 'Metro General Hospital & Trauma Center',
        contactNumber: '+1 415-555-9911',
      );
      repo.simulateDonorAcceptance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sosRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: SosScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('LIVE EMERGENCY BROADCAST'), findsOneWidget);
      expect(find.text('Search Radius'), findsOneWidget);
      expect(find.text('Donors Alerted'), findsOneWidget);
      expect(find.text('Responders'), findsOneWidget);

      // Verify Responders section with simulated responder
      expect(find.text('Live Responders (1)'), findsOneWidget);
      expect(find.text('Marcus Chen'), findsOneWidget);

      // Verify Hospital & Blood Bank Reserve check card
      expect(find.text('Hospital & Blood Bank Reserve'), findsOneWidget);
      expect(find.text('Destination Emergency Center'), findsOneWidget);
      expect(find.text('Emergency Blood Bank Backup'), findsOneWidget);

      // Verify Live Dispatch & Event Log
      expect(find.text('Live Dispatch & Event Log'), findsOneWidget);

      // Verify Action buttons
      expect(find.text('Resolve Emergency'), findsOneWidget);
      expect(find.text('Cancel SOS'), findsOneWidget);

      repo.dispose();
    });

    testWidgets('ResponderCoordinationSheet displays milestone progression and advances status', (WidgetTester tester) async {
      final repo = SosRepository();
      addTearDown(repo.dispose);

      await repo.startBroadcast(
        bloodGroup: 'O-',
        hospitalName: 'Metro General Hospital & Trauma Center',
        contactNumber: '+1 415-555-9911',
      );
      repo.simulateDonorAcceptance();
      final active = await repo.watchActiveBroadcast().first;
      final responder = active!.responders.first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sosRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ResponderCoordinationSheet(responder: responder),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify identity and milestones
      expect(find.text(responder.name), findsOneWidget);
      expect(find.text('Call Donor'), findsOneWidget);
      expect(find.text('Send SMS'), findsOneWidget);
      expect(find.text('Live Responder Milestone'), findsOneWidget);
      expect(find.text('Dispatched & En Route'), findsOneWidget);
      expect(find.text('Arrived at Reception / Blood Bank'), findsOneWidget);
      expect(find.text('Blood Draw in Progress'), findsOneWidget);
      expect(find.text('Emergency Donation Complete'), findsOneWidget);

      // Advance action button
      final advanceButton = find.text('Confirm Donor Arrived at Reception');
      expect(advanceButton, findsOneWidget);

      await tester.ensureVisible(advanceButton);
      await tester.tap(advanceButton);
      await tester.pump(const Duration(milliseconds: 200));

      final updated = await repo.watchActiveBroadcast().first;
      expect(updated?.responders.first.status, equals('arrived'));

      repo.dispose();
    });
  });
}
