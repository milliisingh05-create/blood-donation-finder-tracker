import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_donation_finder/core/services/preferences_service.dart';
import 'package:blood_donation_finder/features/auth/presentation/controllers/auth_controller.dart';
import 'package:blood_donation_finder/features/auth/presentation/screens/login_screen.dart';
import 'package:blood_donation_finder/features/auth/presentation/screens/register_screen.dart';
import 'package:blood_donation_finder/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:blood_donation_finder/features/onboarding/presentation/screens/permission_explanation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Authentication & Onboarding Tests', () {
    testWidgets('OnboardingScreen renders initial slide and page indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Verify title of first slide
      expect(find.text('Instant Emergency SOS'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Tap Next to advance to slide 2
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Real-Time GPS Discovery'), findsOneWidget);
    });

    testWidgets('LoginScreen displays email, password fields and Demo Mode button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.textContaining('Demo Mode'), findsOneWidget);
      expect(find.text('Sign In with Phone OTP'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders all fields, donor toggle, and validates empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.text('Join Blood Finder'), findsOneWidget);
      expect(find.text('Select Blood Group'), findsOneWidget);
      expect(find.text('I want to be a donor'), findsOneWidget);
      expect(find.text('Complete Registration'), findsOneWidget);

      // Scroll to Complete Registration button and tap to trigger form validation
      final submitBtn = find.text('Complete Registration');
      await tester.ensureVisible(submitBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testWidgets('PermissionExplanationScreen displays educational rationale cards and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PermissionExplanationScreen(),
        ),
      );

      expect(find.text('Essential Permissions'), findsOneWidget);
      expect(find.text('GPS Location Access'), findsOneWidget);
      expect(find.text('Emergency Push Alerts'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
    });

    test('PreferencesService persists and resets onboarding status correctly', () async {
      final service = PreferencesService();
      await service.resetOnboarding();

      final initial = await service.hasCompletedOnboarding();
      expect(initial, isFalse);

      await service.setOnboardingCompleted();
      final completed = await service.hasCompletedOnboarding();
      expect(completed, isTrue);

      await service.resetOnboarding();
      final reset = await service.hasCompletedOnboarding();
      expect(reset, isFalse);
    });

    test('AuthController state transitions on demo sign-in and sign-out', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      expect(container.read(authControllerProvider).isAuthenticated, isFalse);

      final success = await controller.signInDemoMode();
      expect(success, isTrue);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      expect(container.read(authControllerProvider).user?.displayName, equals('Marcus Chen'));

      await controller.signOut();
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    });
  });
}
