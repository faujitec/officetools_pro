import 'package:flutter/material.dart';

/// App-wide theme mode (used by [MaterialApp] and persisted via [AppSettings]).
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static String preferenceFromMode(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  static void applyPreference(String? raw) {
    final v = (raw ?? 'light').trim().toLowerCase();
    if (v == 'dark') {
      mode.value = ThemeMode.dark;
    } else if (v == 'system') {
      mode.value = ThemeMode.system;
    } else {
      mode.value = ThemeMode.light;
    }
  }
}
