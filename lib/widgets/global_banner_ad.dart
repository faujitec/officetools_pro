import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:office_toolspro/services/ads_config.dart';
import 'package:office_toolspro/services/consent_service.dart';

class InlineBannerAd extends StatefulWidget {
  const InlineBannerAd({super.key});

  @override
  State<InlineBannerAd> createState() => _InlineBannerAdState();
}

class _InlineBannerAdState extends State<InlineBannerAd> {
  BannerAd? _bannerAd;
  BannerAd? _loadingAd;
  bool _isLoaded = false;
  late final VoidCallback _consentListener;

  @override
  void initState() {
    super.initState();
    _consentListener = () {
      if (!mounted) return;
      if (ConsentService.canRequestAds.value) {
        _loadBanner();
      } else {
        if (_bannerAd != null || _loadingAd != null) {
          _loadingAd?.dispose();
          _bannerAd?.dispose();
          _loadingAd = null;
          _bannerAd = null;
          _isLoaded = false;
          setState(() {});
        }
      }
    };
    ConsentService.canRequestAds.addListener(_consentListener);
    _loadBanner();
  }

  void _loadBanner() {
    if (!AdsConfig.enabled || !AdsConfig.isSupportedPlatform) return;
    if (!ConsentService.canRequestAds.value) return;
    if (_bannerAd != null || _loadingAd != null) return;

    final ad = BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          final banner = ad as BannerAd;
          if (_loadingAd != banner) {
            banner.dispose();
            return;
          }
          if (!mounted) {
            banner.dispose();
            _loadingAd = null;
            return;
          }
          setState(() {
            _bannerAd = banner;
            _loadingAd = null;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          if (_loadingAd == ad) {
            _loadingAd = null;
          }
          ad.dispose();
          if (kDebugMode) {
            debugPrint(
              '[ads] banner load failed (${AdsConfig.bannerAdUnitId}): '
              '${error.message}',
            );
          }
        },
      ),
    );
    _loadingAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    ConsentService.canRequestAds.removeListener(_consentListener);
    if (_loadingAd != null && _loadingAd != _bannerAd) {
      _loadingAd!.dispose();
    }
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsConfig.enabled || !AdsConfig.isSupportedPlatform) {
      return const SizedBox.shrink();
    }
    if (!ConsentService.canRequestAds.value) {
      return const SizedBox.shrink();
    }
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
