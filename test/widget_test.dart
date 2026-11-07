import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emma_drive/main.dart';

void main() {
  testWidgets('EmmaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EmmaApp(),
      ),
    );

    // Verify app widget mounts
    expect(find.byType(EmmaApp), findsOneWidget);

    // Fast-forward past splash screen delay and transitions
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
  });
}
