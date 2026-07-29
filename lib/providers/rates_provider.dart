import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/rate_model.dart';
import '../services/firestore_service.dart';

/// Holds the latest rate per city for all three categories at once, backing
/// the admin dashboard's "today's rates at a glance" screen.
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

  /// [latest] is fed by a live query against `rates` itself (see
  /// firestore_service.dart), so the snapshot listener normally reflects a
  /// save within moments on its own. Both writes below additionally patch
  /// [latest] locally right after the write succeeds, purely so the screen
  /// the admin is looking at updates in the same frame instead of waiting
  /// even that short round trip — the real listener overwrites this the
  /// moment its snapshot arrives, so it's a display shortcut, never a
  /// second source of truth.
  Future<void> addRate(RateModel rate) async {
    await _service.addRate(rate);
    _upsertLocal(rate);
  }

  Future<void> updateRate(RateModel rate) async {
    await _service.updateRate(rate);
    _upsertLocal(rate);
  }

  Future<void> deleteRate(String rateId) => _service.deleteRate(rateId);

  void _upsertLocal(RateModel rate) {
    final list = List<RateModel>.from(latest[rate.category] ?? []);
    final index = list.indexWhere((r) => r.cityId == rate.cityId);
    if (index >= 0) {
      list[index] = rate;
    } else {
      list.add(rate);
    }
    latest[rate.category] = list;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
