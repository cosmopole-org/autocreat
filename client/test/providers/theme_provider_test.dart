import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:autocreat/providers/theme_provider.dart';
import 'package:autocreat/core/constants.dart';

ProviderContainer buildContainer({Map<String, Object> prefs = const {}}) {
  SharedPreferences.setMockInitialValues(prefs);
  late SharedPreferences sharedPrefs;
  SharedPreferences.getInstance().then((p) => sharedPrefs = p);
  // We use a synchronous approach via setMockInitialValues
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWith((ref) {
        // Return a mock prefs that already has the values.
        // The real SharedPreferences.getInstance() is async so we use
        // a workaround: construct a container after setMockInitialValues.
        throw UnimplementedError(
            'Use buildContainerAsync for SharedPreferences tests');
      }),
    ],
  );
}

Future<ProviderContainer> buildContainerAsync(
    {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
    ],
  );
}

void main() {
  group('ThemeNotifier', () {
    test('defaults to light mode when no saved preference', () async {
      final container = await buildContainerAsync();
      addTearDown(container.dispose);
      final theme = container.read(themeProvider);
      expect(theme, ThemeMode.light);
    });

    test('reads dark theme from preferences', () async {
      final container = await buildContainerAsync(
          prefs: {AppConstants.themeKey: 'dark'});
      addTearDown(container.dispose);
      final theme = container.read(themeProvider);
      expect(theme, ThemeMode.dark);
    });

    test('reads light theme from preferences', () async {
      final container = await buildContainerAsync(
          prefs: {AppConstants.themeKey: 'light'});
      addTearDown(container.dispose);
      final theme = container.read(themeProvider);
      expect(theme, ThemeMode.light);
    });

    test('setTheme changes state to dark', () async {
      final container = await buildContainerAsync();
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('setTheme changes state to light', () async {
      final container = await buildContainerAsync(
          prefs: {AppConstants.themeKey: 'dark'});
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).setTheme(ThemeMode.light);
      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('toggleTheme flips from light to dark', () async {
      final container = await buildContainerAsync();
      addTearDown(container.dispose);
      expect(container.read(themeProvider), ThemeMode.light);

      await container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('toggleTheme flips from dark to light', () async {
      final container = await buildContainerAsync(
          prefs: {AppConstants.themeKey: 'dark'});
      addTearDown(container.dispose);

      await container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider), ThemeMode.light);
    });
  });

  group('GlassModeNotifier', () {
    test('defaults to false when no saved preference', () async {
      final container = await buildContainerAsync();
      addTearDown(container.dispose);
      expect(container.read(glassModeProvider), isFalse);
    });

    test('reads saved glass mode', () async {
      final container = await buildContainerAsync(
          prefs: {AppConstants.glassModeKey: true});
      addTearDown(container.dispose);
      expect(container.read(glassModeProvider), isTrue);
    });

    test('setGlassMode enables glass mode', () async {
      final container = await buildContainerAsync();
      addTearDown(container.dispose);

      await container.read(glassModeProvider.notifier).setGlassMode(true);
      expect(container.read(glassModeProvider), isTrue);
    });

    test('toggleGlassMode flips state', () async {
      final container = await buildContainerAsync();
      addTearDown(container.dispose);
      expect(container.read(glassModeProvider), isFalse);

      await container.read(glassModeProvider.notifier).toggleGlassMode();
      expect(container.read(glassModeProvider), isTrue);

      await container.read(glassModeProvider.notifier).toggleGlassMode();
      expect(container.read(glassModeProvider), isFalse);
    });
  });
}
