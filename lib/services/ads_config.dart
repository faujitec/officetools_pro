import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:office_toolspro/constants.dart';

/// Shared AdMob configuration for banner and interstitial units.
class AdsConfig {
  AdsConfig._();

  /// Off in debug unless `--dart-define=ENABLE_ADS=true` or `ADS_IN_DEBUG=true`.
  static const bool enabled = bool.fromEnvironment('ENABLE_ADS') ||
      bool.fromEnvironment('ADS_IN_DEBUG') ||
      !kDebugMode;

  static bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get bannerAdUnitId {
    const overrideAndroid =
        String.fromEnvironment('ADMOB_BANNER_ANDROID');
    const overrideIos = String.fromEnvironment('ADMOB_BANNER_IOS');
    if (Platform.isAndroid) {
      return overrideAndroid.isNotEmpty
          ? overrideAndroid
          : AppConstants.admobBannerAndroid;
    }
    // Same production units unless you pass ADMOB_BANNER_IOS or add iOS units in AdMob.
    return overrideIos.isNotEmpty
        ? overrideIos
        : AppConstants.admobBannerAndroid;
  }

  static String get interstitialAdUnitId {
    const overrideAndroid =
        String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
    const overrideIos = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');
    if (Platform.isAndroid) {
      return overrideAndroid.isNotEmpty
          ? overrideAndroid
          : AppConstants.admobInterstitialAndroid;
    }
    return overrideIos.isNotEmpty
        ? overrideIos
        : AppConstants.admobInterstitialAndroid;
  }
}
