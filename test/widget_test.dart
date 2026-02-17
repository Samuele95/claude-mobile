import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:claude_mobile/app.dart';
import 'package:claude_mobile/features/settings/preferences_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialPreferencesProvider
              .overrideWithValue(const AppPreferences()),
        ],
        child: const ClaudeMobileApp(),
      ),
    );

    // Verify the app renders without crashing.
    expect(find.text('Claude Carry'), findsOneWidget);
  });
}
