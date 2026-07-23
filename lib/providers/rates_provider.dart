import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/rate_model.dart';
import '../services/firestore_service.dart';

/// Holds the latest rate per city for all three categories at once, so the
/// user-facing Rates screen and Home feed don't each open their own
/// Firestore listeners.
class RatesProvider extends ChangeNotifier {
  final FirestoreService _service;
  final Map<RateCategory, StreamSubscription<List<RateModel>>> _subs = {};

  RatesProvider(this._service) {
    for (final category in RateCategory.values) {
      latest[category] = [];
      loading[category] = true;
      _subs[category] = _service.watchLatestRatesForCategory(category).listen((data) {
        latest[category] = data;
        loading[category] = false;
        notifyListeners();
      });
    }
  }

  final Map<RateCategory, List<RateModel>> latest = {};
  final Map<RateCategory, bool> loading = {};

  List<RateModel> ratesFor(RateCategory category) => latest[category] ?? [];

  Future<void> addRate(RateModel rate) => _service.addRate(rate);
  Future<void> updateRate(RateModel rate) => _service.updateRate(rate);
  Future<void> deleteRate(String rateId) => _service.deleteRate(rateId);

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
