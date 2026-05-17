import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autocreat/main.dart';
import 'package:autocreat/providers/theme_provider.dart';

void main() {
  group('AutoCreat App smoke tests', () {
    testWidgets('App builds with ProviderScope', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
          ],
          child: const AutoCreatApp(),
        ),
      );

      // The app should render with a ProviderScope.
      expect(find.byType(ProviderScope), findsOneWidget);
    });

    testWidgets('App renders with default (light) theme', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
          ],
          child: const AutoCreatApp(),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('App renders with dark theme preference', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final sp = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
          ],
          child: const AutoCreatApp(),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('App renders with glass mode enabled', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'glass_mode': true});
      final sp = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
          ],
          child: const AutoCreatApp(),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
