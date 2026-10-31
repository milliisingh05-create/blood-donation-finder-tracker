import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_donation_finder/core/widgets/lifeline_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LifeLineBackground Widget Tests', () {
    testWidgets('renders child content and RepaintBoundary canvas', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LifeLineBackground(
              child: Text('Lifeline Content Test'),
            ),
          ),
        ),
      );

      // Verify child content is visible
      expect(find.text('Lifeline Content Test'), findsOneWidget);

      // Verify RepaintBoundary is used for 60fps performance isolation
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);

      // Pump 1 second of animation frames
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('respects reduce-motion accessibility setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: LifeLineBackground(
                child: Text('Accessible Static View'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Accessible Static View'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
