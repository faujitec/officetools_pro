import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsState {
  final bool autoDetectScanEdges;
  final bool keepOriginalScanCopy;
  final bool cloudFeaturesEnabled;
  final int defaultImageQuality;
  final Set<String> dismissedTips;

  const AppSettingsState({
    required this.autoDetectScanEdges,
    required this.keepOriginalScanCopy,
    required this.cloudFeaturesEnabled,
    required this.defaultImageQuality,
    required this.dismissedTips,
  });

  factory AppSettingsState.defaults() => const AppSettingsState(
        autoDetectScanEdges: true,
        keepOriginalScanCopy: false,
        cloudFeaturesEnabled: true,
        defaultImageQuality: 80,
        dismissedTips: <String>{},
      );

  AppSettingsState copyWith({
    bool? autoDetectScanEdges,
    bool? keepOriginalScanCopy,
    bool? cloudFeaturesEnabled,
    int? defaultImageQuality,
    Set<String>? dismissedTips,
  }) {
    return AppSettingsState(
      autoDetectScanEdges: autoDetectScanEdges ?? this.autoDetectScanEdges,
      keepOriginalScanCopy: keepOriginalScanCopy ?? this.keepOriginalScanCopy,
      cloudFeaturesEnabled: cloudFeaturesEnabled ?? this.cloudFeaturesEnabled,
      defaultImageQuality: defaultImageQuality ?? this.defaultImageQuality,
      dismissedTips: dismissedTips ?? this.dismissedTips,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'autoDetectScanEdges': autoDetectScanEdges,
        'keepOriginalScanCopy': keepOriginalScanCopy,
        'cloudFeaturesEnabled': cloudFeaturesEnabled,
        'defaultImageQuality': defaultImageQuality,
        'dismissedTips': dismissedTips.toList(growable: false),
      };

  factory AppSettingsState.fromJson(Map<String, dynamic> json) {
    final tips =
        (json['dismissedTips'] as List?)?.map((e) => e.toString()).toSet() ??
            <String>{};
    final quality = (json['defaultImageQuality'] as num?)?.toInt() ?? 80;
    return AppSettingsState(
      autoDetectScanEdges: json['autoDetectScanEdges'] as bool? ?? true,
      keepOriginalScanCopy: json['keepOriginalScanCopy'] as bool? ?? false,
      cloudFeaturesEnabled: json['cloudFeaturesEnabled'] as bool? ?? true,
      defaultImageQuality: quality.clamp(50, 100),
      dismissedTips: tips,
    );
  }
}

class AppSettings {
  AppSettings._();

  static const _prefsKey = 'app_settings_v1';
  static final ValueNotifier<AppSettingsState> state =
      ValueNotifier<AppSettingsState>(AppSettingsState.defaults());

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
      // Non-fatal.
    }
  }

  static void update(AppSettingsState next) {
    state.value = next;
    _save();
  }

  static void dismissTip(String tipId) {
    final nextTips = Set<String>.from(state.value.dismissedTips)..add(tipId);
    update(state.value.copyWith(dismissedTips: nextTips));
  }

  static bool shouldShowTip(String tipId) =>
      !state.value.dismissedTips.contains(tipId);
}
