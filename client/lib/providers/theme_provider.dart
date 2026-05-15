import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../data/mock_ui_text.dart';

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

class GlassModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(AppConstants.glassModeKey) ?? false;
  }

  Future<void> setGlassMode(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.glassModeKey, enabled);
    state = enabled;
  }

  Future<void> toggleGlassMode() async {
    await setGlassMode(!state);
  }
}


class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppLanguageX.fromCode(prefs.getString(AppConstants.languageKey));
  }

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppConstants.languageKey, language.code);
    MockUiText.configureLanguage(language);
    state = language;
  }

  Future<void> toggleLanguage() async {
    await setLanguage(state == AppLanguage.english ? AppLanguage.persian : AppLanguage.english);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);

final glassModeProvider = NotifierProvider<GlassModeNotifier, bool>(GlassModeNotifier.new);
