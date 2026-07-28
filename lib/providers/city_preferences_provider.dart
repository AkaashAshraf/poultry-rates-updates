import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Tracks which cities this device's user wants to follow. Local-first
/// (SharedPreferences) so the UI never blocks on a network round trip, and
/// mirrored to the user's Firestore doc — keyed by their Firebase UID,
/// which is one-per-install since regular users are only ever signed in
/// anonymously (the "one user = one device" model) — so the
/// notify-on-rate-update Cloud Function knows who to notify.
class CityPreferencesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthService _authService;

  CityPreferencesProvider(this._firestoreService, this._authService) {
    ready = _load();
  }

  /// Resolves once the saved preferences have been read from disk. Callers
  /// that need to make a routing decision based on [hasOnboarded] (the
  /// splash screen) should await this first.
  late final Future<void> ready;

  List<String> _preferredCityIds = [];
  bool _hasOnboarded = false;

  List<String> get preferredCityIds => _preferredCityIds;
  bool get hasOnboarded => _hasOnboarded;

  bool isPreferred(String cityId) => _preferredCityIds.contains(cityId);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredCityIds = prefs.getStringList(AppConstants.prefsPreferredCitiesKey) ?? [];
    _hasOnboarded = prefs.getBool(AppConstants.prefsOnboardedKey) ?? false;
    notifyListeners();
  }

  /// Saves the new selection locally (instant) and pushes it to Firestore
  /// (fire-and-forget — never blocks the UI). Marks onboarding complete so
  /// the picker isn't shown again on next launch.
  Future<void> setPreferredCities(List<String> cityIds) async {
    _preferredCityIds = cityIds;
    _hasOnboarded = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.prefsPreferredCitiesKey, cityIds);
    await prefs.setBool(AppConstants.prefsOnboardedKey, true);

    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      unawaited(_firestoreService.updatePreferredCities(uid, cityIds));
    }
  }
}
