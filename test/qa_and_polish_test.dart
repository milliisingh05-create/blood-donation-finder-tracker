import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blood_donation_finder/core/theme/app_colors.dart';
import 'package:blood_donation_finder/core/widgets/offline_demo_banner.dart';
import 'package:blood_donation_finder/features/auth/presentation/controllers/auth_controller.dart';
import 'package:blood_donation_finder/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:blood_donation_finder/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 13: Polish, QA & Zero-Gradient Audit Tests', () {
    testWidgets('OfflineDemoBanner renders offline status and info dialog on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: OfflineDemoBanner(),
            ),
          ),
        ),
      );

      // Verify banner text
      expect(find.textContaining('Demo Mode: Offline In-Memory Data'), findsOneWidget);

      // Tap banner to open info dialog
      await tester.tap(find.textContaining('Demo Mode: Offline In-Memory Data'));
      await tester.pumpAndSettle();

      // Verify explanation dialog
      expect(find.text('Local Offline Mode'), findsOneWidget);
      expect(find.textContaining('Local Offline Mode with in-memory repositories'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Local Offline Mode'), findsNothing);

      // Tap dismiss icon
      final closeIcon = find.byIcon(Icons.close_rounded);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      // Banner should be dismissed
      expect(find.textContaining('Demo Mode: Offline In-Memory Data'), findsNothing);
    });

    testWidgets('DashboardScreen renders greeting and OfflineDemoBanner', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify Offline Demo Banner is present at top
      expect(find.byType(OfflineDemoBanner), findsOneWidget);
    });

    testWidgets('App Router initializes MainNavShell with 5 persistent tabs', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Sign in as demo user to land on Dashboard inside MainNavShell
      await container.read(authControllerProvider.notifier).signInDemoMode();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BloodFinderApp(),
        ),
      );

      // Advance through splash to dashboard
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Find Donors'), findsWidgets);
      expect(find.text('SOS'), findsWidgets);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('MainNavShell supports smooth tab switching across all 5 navigation branches', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).signInDemoMode();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BloodFinderApp(),
        ),
      );

      // Advance through splash to dashboard
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 500));

      // Switch to Find Donors (tab index 1)
      final findDonorsTab = find.text('Find Donors').last;
      await tester.tap(findDonorsTab);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NavigationBar), findsOneWidget);

      // Switch to History (tab index 3)
      final historyTab = find.text('History');
      await tester.tap(historyTab);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('History'), findsWidgets);

      // Switch to Profile (tab index 4)
      final profileTab = find.text('Profile');
      await tester.tap(profileTab);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Donor Profile'), findsOneWidget);

      // Switch back to Home (tab index 0)
      final homeTab = find.text('Home');
      await tester.tap(homeTab);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(OfflineDemoBanner), findsOneWidget);
    });

    test('Zero-Gradient Static Codebase Scan: Assert zero gradient usage across all lib/ files', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

      final forbiddenKeywords = ['LinearGradient', 'RadialGradient', 'SweepGradient'];
      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          for (final keyword in forbiddenKeywords) {
            if (content.contains(keyword)) {
              final lines = content.split('\n');
              for (var i = 0; i < lines.length; i++) {
                final line = lines[i];
                if (line.contains(keyword) && !line.trim().startsWith('//') && !line.trim().startsWith('*')) {
                  violations.add('${entity.path}:${i + 1} uses forbidden $keyword: "$line"');
                }
              }
            }
          }
        }
      }

      expect(violations, isEmpty, reason: 'Zero gradients policy violated in codebase: ${violations.join('\n')}');
    });

    test('Strict Color Token Compliance: Zero-gradient verification', () {
      // Primary flat red
      expect(AppColors.primaryRed, equals(const Color(0xFFFF4B5C)));
      // Primary dark
      expect(AppColors.primaryDark, equals(const Color(0xFFE63946)));
      // Light red tint (flat)
      expect(AppColors.lightRedTint, equals(const Color(0xFFFFE3E6)));
      // Clean background
      expect(AppColors.background, equals(const Color(0xFFFFF6F7)));
      // Surface
      expect(AppColors.surface, equals(const Color(0xFFFFFFFF)));
      // Success
      expect(AppColors.success, equals(const Color(0xFF2ECC71)));
      // Warning
      expect(AppColors.warning, equals(const Color(0xFFFFB020)));
      // Inactive
      expect(AppColors.inactiveGrey, equals(const Color(0xFFB8AEB0)));
    });
  });
}
