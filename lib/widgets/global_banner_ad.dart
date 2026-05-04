import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const bool _adsEnabled =
    bool.fromEnvironment('ENABLE_ADS', defaultValue: true) && !kDebugMode;

class GlobalBannerAd extends StatefulWidget {
  final Widget child;

  const GlobalBannerAd({super.key, required this.child});

  @override
  State<GlobalBannerAd> createState() => _GlobalBannerAdState();
}

class _GlobalBannerAdState extends State<GlobalBannerAd> {
  BannerAd? _bannerAd;
  BannerAd? _loadingAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (!_adsEnabled || kIsWeb) return;
    if (_bannerAd != null || _loadingAd != null) return;

    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716';

    final ad = BannerAd(
      adUnitId: adUnitId,
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
        onAdFailedToLoad: (ad, _) {
          if (_loadingAd == ad) {
            _loadingAd = null;
          }
          ad.dispose();
        },
      ),
    );
    _loadingAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    if (_loadingAd != null && _loadingAd != _bannerAd) {
      _loadingAd!.dispose();
    }
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_adsEnabled) {
      return widget.child;
    }
    final adHeight = _isLoaded && _bannerAd != null ? _bannerAd!.size.height.toDouble() : 0.0;
    final topInset = MediaQuery.of(context).padding.top;
    final contentTopPadding = adHeight > 0 ? adHeight + topInset : 0.0;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: contentTopPadding),
          child: widget.child,
        ),
        if (_isLoaded && _bannerAd != null)
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: adHeight,
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          ),
      ],
    );
  }
}

class InlineBannerAd extends StatefulWidget {
  const InlineBannerAd({super.key});

  @override
  State<InlineBannerAd> createState() => _InlineBannerAdState();
}

class _InlineBannerAdState extends State<InlineBannerAd> {
  BannerAd? _bannerAd;
  BannerAd? _loadingAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (!_adsEnabled || kIsWeb) return;
    if (_bannerAd != null || _loadingAd != null) return;

    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716';

    final ad = BannerAd(
      adUnitId: adUnitId,
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
        onAdFailedToLoad: (ad, _) {
          if (_loadingAd == ad) {
            _loadingAd = null;
          }
          ad.dispose();
        },
      ),
    );
    _loadingAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    if (_loadingAd != null && _loadingAd != _bannerAd) {
      _loadingAd!.dispose();
    }
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_adsEnabled) {
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
