import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Theme mode notifier for dark/light mode toggle
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'theme_mode';
  final SharedPreferences _prefs;
  
  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));
  
  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
  
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs.setString(_key, mode.name);
  }
  
  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
  
  bool get isDark => state == ThemeMode.dark;
}

/// Locale notifier for language toggle
class LocaleNotifier extends StateNotifier<Locale> {
  static const String _key = 'locale';
  final SharedPreferences _prefs;
  
  LocaleNotifier(this._prefs) : super(_loadLocale(_prefs));
  
  static Locale _loadLocale(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    if (value == 'en') {
      return const Locale('en');
    }
    return const Locale('ar');  // Default to Arabic
  }
  
  void setLocale(Locale locale) {
    state = locale;
    _prefs.setString(_key, locale.languageCode);
  }
  
  void toggleLocale() {
    if (state.languageCode == 'ar') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('ar'));
    }
  }
  
  bool get isArabic => state.languageCode == 'ar';
}

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// Locale provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

/// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
