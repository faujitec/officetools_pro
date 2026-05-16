import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:office_toolspro/constants.dart';

/// Enables drawing under the system bars; pair with [overlayForTheme].
void enableEdgeToEdgeUi() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

/// Navigation / status styling matched to the active [ThemeData] scaffold.
SystemUiOverlayStyle overlayForTheme(ThemeData theme) {
  final bg = theme.scaffoldBackgroundColor;
  final isDark = theme.brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: bg,
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Global fallback when [BuildContext] / [ThemeData] is unavailable.
SystemUiOverlayStyle overlayForBrightness(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF121212) : AppConstants.backgroundGrey;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: bg,
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}
