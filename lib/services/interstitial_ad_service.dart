import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/ad_constants.dart';

/// Manages the app's capped interstitial ("video") ad slot.
///
/// Per product requirement, a single user must never see more than
/// [AdConstants.maxInterstitialAdsPerDay] of these ads in one calendar day.
/// The count is persisted in SharedPreferences (keyed by today's date) so
/// the cap survives app restarts, not just the current session.
///
/// One instance is created in main.dart and shared via Provider so the app
/// only ever preloads a single interstitial at a time.
class InterstitialAdService {
  InterstitialAd? _ad;
  bool _isLoading = false;

  static const _prefsDateKey = 'interstitial_ad_shown_date';
  static const _prefsCountKey = 'interstitial_ad_shown_count';

  /// Kicks off preloading the first ad. Call once at app start so the ad is
  /// likely already cached by the time the first trigger point fires.
  void preload() {
    if (AdConstants.interstitialAdUnitId == null) return; // e.g. web
    _load();
  }

  void _load() {
    final unitId = AdConstants.interstitialAdUnitId;
    if (unitId == null || _isLoading || _ad != null) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// Shows the preloaded ad if: one is ready, AND today's shown-count is
  /// still under the daily cap. Silently does nothing otherwise (e.g. cap
  /// reached, or the ad hasn't finished loading yet) — callers don't need
  /// to handle a "couldn't show" case specially.
  Future<void> maybeShow() async {
    final unitId = AdConstants.interstitialAdUnitId;
    if (unitId == null) return;

    final remaining = await _remainingToday();
    if (remaining <= 0) return;

    final ad = _ad;
    if (ad == null) {
      // Not loaded yet (e.g. slow network) — try to have one ready for the
      // *next* trigger point instead of blocking this one.
      _load();
      return;
    }

    _ad = null; // Consumed — clear before showing so dispose() below can't
    // race a second maybeShow() call.

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _recordShown();
        _load(); // Preload the next one, if the cap allows another today.
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('InterstitialAd failed to show: $error');
        ad.dispose();
        _load();
      },
    );
    await ad.show();
  }

  Future<int> _remainingToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_prefsDateKey);
    final shownToday = storedDate == today ? (prefs.getInt(_prefsCountKey) ?? 0) : 0;
    return AdConstants.maxInterstitialAdsPerDay - shownToday;
  }

  Future<void> _recordShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final storedDate = prefs.getString(_prefsDateKey);
    final shownToday = storedDate == today ? (prefs.getInt(_prefsCountKey) ?? 0) : 0;
    await prefs.setString(_prefsDateKey, today);
    await prefs.setInt(_prefsCountKey, shownToday + 1);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
