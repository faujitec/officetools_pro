import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  ConsentService._();

  static final ValueNotifier<bool> canRequestAds = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> privacyOptionsRequired =
      ValueNotifier<bool>(false);

  static bool _requestedOnce = false;

  static Future<void> gatherConsent() async {
    if (_requestedOnce) return;
    _requestedOnce = true;

    final params = ConsentRequestParameters(
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              // Add testIdentifiers here when debugging consent flows.
              testIdentifiers: const <String>[],
            )
          : null,
    );

    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
            // Even if consent collection fails, UMP may still allow ads based on
            // previous session state.
            await _refreshFlags();
            if (!completer.isCompleted) completer.complete();
          });
        } catch (_) {
          await _refreshFlags();
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError _) async {
        await _refreshFlags();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  static Future<void> _refreshFlags() async {
    try {
      canRequestAds.value = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      canRequestAds.value = false;
    }
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      privacyOptionsRequired.value = false;
    }
  }

  static Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? _) async {
      await _refreshFlags();
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }
}
