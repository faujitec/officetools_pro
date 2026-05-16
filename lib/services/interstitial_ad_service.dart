import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:office_toolspro/services/ads_config.dart';
import 'package:office_toolspro/services/consent_service.dart';

/// Shows a full-screen interstitial after [clicksPerInterstitial] user taps.
class InterstitialAdService {
  InterstitialAdService._();

  static final InterstitialAdService instance = InterstitialAdService._();

  static const int clicksPerInterstitial = 15;

  int _clickCount = 0;
  InterstitialAd? _interstitial;
  bool _loading = false;
  bool _isShowing = false;
  late final VoidCallback _consentListener;

  void initialize() {
    if (!AdsConfig.enabled || !AdsConfig.isSupportedPlatform) return;

    _consentListener = () {
      if (ConsentService.canRequestAds.value) {
        _loadInterstitial();
      } else {
        _disposeInterstitial();
        _clickCount = 0;
      }
    };
    ConsentService.canRequestAds.addListener(_consentListener);
    if (ConsentService.canRequestAds.value) {
      _loadInterstitial();
    }
  }

  void dispose() {
    if (!AdsConfig.enabled || !AdsConfig.isSupportedPlatform) return;
    ConsentService.canRequestAds.removeListener(_consentListener);
    _disposeInterstitial();
  }

  /// Counts a deliberate tap (not scroll/drag). Shows ad every 15 taps.
  void recordTap() {
    if (!AdsConfig.enabled || !AdsConfig.isSupportedPlatform) return;
    if (!ConsentService.canRequestAds.value) return;
    if (_isShowing) return;

    _clickCount++;
    if (_clickCount < clicksPerInterstitial) return;

    _clickCount = 0;
    _showInterstitial();
  }

  void _loadInterstitial() {
    if (!AdsConfig.enabled || !AdsConfig.isSupportedPlatform) return;
    if (!ConsentService.canRequestAds.value) return;
    if (_interstitial != null || _loading) return;

    _loading = true;
    InterstitialAd.load(
      adUnitId: AdsConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitial?.dispose();
          _interstitial = ad;
          if (kDebugMode) {
            debugPrint(
              '[ads] interstitial loaded (${AdsConfig.interstitialAdUnitId})',
            );
          }
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          if (kDebugMode) {
            debugPrint('[ads] interstitial load failed: ${error.message}');
          }
        },
      ),
    );
  }

  void _showInterstitial() {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    _isShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissedAd) {
        dismissedAd.dispose();
        if (_interstitial == dismissedAd) {
          _interstitial = null;
        }
        _isShowing = false;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        if (_interstitial == failedAd) {
          _interstitial = null;
        }
        _isShowing = false;
        if (kDebugMode) {
          debugPrint('[ads] interstitial show failed: ${error.message}');
        }
        _loadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
  }

  void _disposeInterstitial() {
    _interstitial?.dispose();
    _interstitial = null;
    _loading = false;
    _isShowing = false;
  }
}
