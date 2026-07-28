import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob configuration for the bottom banner shown on every user-facing
/// screen (see widgets/banner_ad_slot.dart).
///
/// These are Google's public *test* ad unit IDs — safe to ship as-is
/// (they only ever serve clearly-labeled test creatives, never real ads),
/// but they earn nothing. Before a real release:
///
/// 1. Sign up at https://admob.google.com and create an app entry for
///    each platform you ship.
/// 2. Create one Banner ad unit per platform and replace the IDs below.
/// 3. Replace the test `APPLICATION_ID` meta-data in
///    android/app/src/main/AndroidManifest.xml with your real Android app
///    ID from AdMob.
/// 4. For iOS: add a `GADApplicationIdentifier` key (your real iOS app ID)
///    to ios/Runner/Info.plist, plus the `SKAdNetworkItems` array from
///    https://developers.google.com/admob/ios/quick-start#update_your_infoplist
///    — that list changes over time, so copy it fresh from Google's docs
///    rather than from old code.
class AdConstants {
  AdConstants._();

  static const _testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static String? get bannerAdUnitId {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return _testAndroidBannerId;
    if (Platform.isIOS) return _testIosBannerId;
    return null;
  }

  // Interstitial (full-screen) ad unit, used for the capped video ad slot —
  // see services/interstitial_ad_service.dart. AdMob's auction serves
  // either a static or video creative on this format depending on
  // advertiser demand; you don't need a separate "video-only" ad unit for
  // production.
  static const _testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  static String? get interstitialAdUnitId {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return _testAndroidInterstitialId;
    if (Platform.isIOS) return _testIosInterstitialId;
    return null;
  }

  /// Hard daily cap on how many interstitial video ads a single user/device
  /// can be shown, per the user's explicit requirement.
  static const int maxInterstitialAdsPerDay = 2;
}
