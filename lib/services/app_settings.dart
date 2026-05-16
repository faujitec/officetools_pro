import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsState {
  final bool autoDetectScanEdges;
  final bool keepOriginalScanCopy;
  final int defaultImageQuality;
  final Set<String> dismissedTips;

  /// One of: `light`, `dark`, `system`.
  final String themePreference;

  const AppSettingsState({
    required this.autoDetectScanEdges,
    required this.keepOriginalScanCopy,
    required this.defaultImageQuality,
    required this.dismissedTips,
    required this.themePreference,
  });

  factory AppSettingsState.defaults() => const AppSettingsState(
        autoDetectScanEdges: true,
        keepOriginalScanCopy: false,
        defaultImageQuality: 80,
        dismissedTips: <String>{},
        themePreference: 'light',
      );

  AppSettingsState copyWith({
    bool? autoDetectScanEdges,
    bool? keepOriginalScanCopy,
    int? defaultImageQuality,
    Set<String>? dismissedTips,
    String? themePreference,
  }) {
    return AppSettingsState(
      autoDetectScanEdges: autoDetectScanEdges ?? this.autoDetectScanEdges,
      keepOriginalScanCopy: keepOriginalScanCopy ?? this.keepOriginalScanCopy,
      defaultImageQuality: defaultImageQuality ?? this.defaultImageQuality,
      dismissedTips: dismissedTips ?? this.dismissedTips,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'autoDetectScanEdges': autoDetectScanEdges,
        'keepOriginalScanCopy': keepOriginalScanCopy,
        'defaultImageQuality': defaultImageQuality,
        'dismissedTips': dismissedTips.toList(growable: false),
        'themePreference': themePreference,
      };

  static String _normalizeTheme(String? raw) {
    final v = (raw ?? 'light').trim().toLowerCase();
    if (v == 'dark' || v == 'system' || v == 'light') return v;
    return 'light';
  }

  factory AppSettingsState.fromJson(Map<String, dynamic> json) {
    final tips =
        (json['dismissedTips'] as List?)?.map((e) => e.toString()).toSet() ??
            <String>{};
    final quality = (json['defaultImageQuality'] as num?)?.toInt() ?? 80;
    return AppSettingsState(
      autoDetectScanEdges: json['autoDetectScanEdges'] as bool? ?? true,
      keepOriginalScanCopy: json['keepOriginalScanCopy'] as bool? ?? false,
      defaultImageQuality: quality.clamp(50, 100),
      dismissedTips: tips,
      themePreference: _normalizeTheme(json['themePreference'] as String?),
    );
  }
}

class AppSettings {
  AppSettings._();

  static const _prefsKey = 'app_settings_v1';
  static final ValueNotifier<AppSettingsState> state =
      ValueNotifier<AppSettingsState>(AppSettingsState.defaults());

  static Timer? _saveDebounceTimer;
  static const Duration _saveDebounce = Duration(milliseconds: 450);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      state.value = AppSettingsState.fromJson(decoded);
    } catch (_) {
      // Ignore malformed cache.
    }
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(state.value.toJson()));
    } catch (_) {
      // Storage full or prefs unavailable — non-fatal.
    }
  }

  /// Updates in-memory settings immediately; persists after a short debounce.
  static void update(AppSettingsState next) {
    state.value = next;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_saveDebounce, () {
      _save();
      _saveDebounceTimer = null;
    });
  }

  static void dismissTip(String tipId) {
    final nextTips = Set<String>.from(state.value.dismissedTips)..add(tipId);
    update(state.value.copyWith(dismissedTips: nextTips));
  }

  static bool shouldShowTip(String tipId) =>
      !state.value.dismissedTips.contains(tipId);
}
