import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static void logEvent(String name, {Map<String, String>? props}) {
    final payload = props == null || props.isEmpty
        ? ''
        : props.entries.map((e) => '${e.key}=${e.value}').join(', ');
    debugPrint('[analytics] $name ${payload.isEmpty ? '' : '| $payload'}');
  }
}
