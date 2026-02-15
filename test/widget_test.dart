import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claude_mobile/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ClaudeMobileApp()),
    );

    // Verify the app renders without crashing.
    expect(find.text('Claude Mobile'), findsOneWidget);
  });
}
