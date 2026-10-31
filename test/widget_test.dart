import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blood_donation_finder/main.dart';

void main() {
  testWidgets('BloodFinderApp smoke test - verifies initial render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BloodFinderApp(),
      ),
    );

    // Initial splash frame verification
    expect(find.byType(BloodFinderApp), findsOneWidget);

    // Advance time past the splash delay (1800ms)
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
