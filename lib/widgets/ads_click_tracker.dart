import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:office_toolspro/services/ads_config.dart';
import 'package:office_toolspro/services/interstitial_ad_service.dart';

/// Counts deliberate taps app-wide for interstitial frequency capping.
class AdsClickTracker extends StatefulWidget {
  final Widget child;

  const AdsClickTracker({super.key, required this.child});

  @override
  State<AdsClickTracker> createState() => _AdsClickTrackerState();
}

class _AdsClickTrackerState extends State<AdsClickTracker> {
  static const double _maxTapTravelPx = 18;
  static const int _maxTapDurationMs = 450;

  Offset? _downPosition;
  DateTime? _downTime;

  void _onPointerDown(PointerDownEvent event) {
    if (!_shouldTrack(event)) return;
    _downPosition = event.position;
    _downTime = DateTime.now();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_shouldTrack(event)) return;
    final downPos = _downPosition;
    final downTime = _downTime;
    _downPosition = null;
    _downTime = null;
    if (downPos == null || downTime == null) return;

    final duration = DateTime.now().difference(downTime).inMilliseconds;
    if (duration > _maxTapDurationMs) return;

    final delta = event.position - downPos;
    if (delta.distance > _maxTapTravelPx) return;

    InterstitialAdService.instance.recordTap();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _downPosition = null;
    _downTime = null;
  }

  bool _shouldTrack(PointerEvent event) {
    if (!AdsConfig.enabled || !AdsConfig.isSupportedPlatform) return false;
    return event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.mouse ||
        event.kind == PointerDeviceKind.stylus;
  }

  @override
  Widget build(BuildContext context) {
    if (!AdsConfig.enabled || !AdsConfig.isSupportedPlatform) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
