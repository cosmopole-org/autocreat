import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedTheme = prefs.getString(AppConstants.themeKey);
    if (savedTheme == 'dark') return ThemeMode.dark;
    if (savedTheme == 'light') return ThemeMode.light;
    return ThemeMode.light;
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    switch (mode) {
      case ThemeMode.dark:
        await prefs.setString(AppConstants.themeKey, 'dark');
        break;
      case ThemeMode.light:
        await prefs.setString(AppConstants.themeKey, 'light');
        break;
      case ThemeMode.system:
        await prefs.remove(AppConstants.themeKey);
        break;
    }
    state = mode;
  }

  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.dark;
    await setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
