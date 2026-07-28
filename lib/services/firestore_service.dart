import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/city_model.dart';
import '../models/rate_model.dart';
import '../models/app_user_model.dart';
import '../models/news_model.dart';
import '../models/app_onboarding_content_model.dart';
import '../models/app_version_config_model.dart';

/// Single place for every Firestore read/write in the app.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------
  // Cities
  // ---------------------------------------------------------------------

  Stream<List<CityModel>> watchCities({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _db.collection(FirestoreCollections.cities);
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map((d) => CityModel.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.nameEn.compareTo(b.nameEn)),
        );
  }

  Future<List<CityModel>> fetchCitiesOnce({bool activeOnly = true}) async {
    Query<Map<String, dynamic>> query = _db.collection(FirestoreCollections.cities);
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snap = await query.get();
    final list = snap.docs.map((d) => CityModel.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => a.nameEn.compareTo(b.nameEn));
    return list;
  }

  Future<void> addCity(CityModel city) {
    return _db.collection(FirestoreCollections.cities).add(city.toMap());
  }

  Future<void> updateCity(CityModel city) {
    return _db.collection(FirestoreCollections.cities).doc(city.id).update(city.toMap());
  }

  Future<void> deleteCity(String cityId) {
    return _db.collection(FirestoreCollections.cities).doc(cityId).delete();
  }

  // ---------------------------------------------------------------------
  // Rates
  // ---------------------------------------------------------------------

  /// Latest rate per city for a given category, used on the admin
  /// dashboard's "today's rates at a glance" screen to show each city's
  /// current price and flag which ones are still pending today.
  ///
  /// Queries `rates` directly (capped at [limit] most-recent entries,
  /// deduped to the newest per city) rather than reading the `currentRates`
  /// mirror that the syncCurrentRateOnWrite Cloud Function maintains. That
  /// mirror is fine in principle, but the dashboard depending on it meant
  /// "who's still pending" could be stuck on stale data — right after a
  /// save, or indefinitely on a fresh app load, whenever that function
  /// hadn't (or hasn't) caught up. Reading `rates` directly means the
  /// dashboard always matches what was actually written, with no
  /// server-side round trip to wait on. [limit] comfortably covers a full
  /// day's admin updates across every city without scanning the entire,
  /// ever-growing history.
  Stream<List<RateModel>> watchLatestRatesForCategory(RateCategory category, {int limit = 500}) {
    return _db
        .collection(FirestoreCollections.rates)
        .where('category', isEqualTo: category.key)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final seenCities = <String>{};
      final result = <RateModel>[];
      for (final d in snap.docs) {
        final rate = RateModel.fromMap(d.id, d.data());
        if (seenCities.add(rate.cityId)) {
          result.add(rate);
        }
      }
      result.sort((a, b) => a.cityName('en').compareTo(b.cityName('en')));
      return result;
    });
  }

  /// Full (admin) history list for a category, newest first.
  Stream<List<RateModel>> watchAllRatesForCategory(RateCategory category, {String? cityId}) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestoreCollections.rates)
        .where('category', isEqualTo: category.key);
    if (cityId != null) {
      query = query.where('cityId', isEqualTo: cityId);
    }
    return query.orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => RateModel.fromMap(d.id, d.data())).toList(),
        );
  }

  /// History for one city + category, oldest first — feeds the trend chart.
  Stream<List<RateModel>> watchRateHistory({
    required RateCategory category,
    required String cityId,
    int limit = 30,
  }) {
    return _db
        .collection(FirestoreCollections.rates)
        .where('category', isEqualTo: category.key)
        .where('cityId', isEqualTo: cityId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => RateModel.fromMap(d.id, d.data())).toList();
      return list.reversed.toList();
    });
  }

  /// Live rate history for the user-facing Rates tab: every entry (not
  /// deduped per city) from the last [days] days, newest first. Re-uses
  /// the same category+cityId+date composite index as [watchAllRatesForCategory]
  /// / [watchRateHistory] — a range filter on `date` alongside the
  /// existing `orderBy('date')` doesn't require a separate index.
  Stream<List<RateModel>> watchRecentRateHistory({
    required RateCategory category,
    String? cityId,
    required int days,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    Query<Map<String, dynamic>> query = _db
        .collection(FirestoreCollections.rates)
        .where('category', isEqualTo: category.key);
    if (cityId != null) {
      query = query.where('cityId', isEqualTo: cityId);
    }
    return query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RateModel.fromMap(d.id, d.data())).toList());
  }

  /// One page of history strictly older than [before], for "load older"
  /// pagination once the initial [watchRecentRateHistory] window has been
  /// exhausted. A one-time fetch rather than a stream — older history
  /// doesn't need to update live.
  Future<List<RateModel>> fetchOlderRateHistory({
    required RateCategory category,
    String? cityId,
    required DateTime before,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestoreCollections.rates)
        .where('category', isEqualTo: category.key);
    if (cityId != null) {
      query = query.where('cityId', isEqualTo: cityId);
    }
    final snap = await query
        .where('date', isLessThan: Timestamp.fromDate(before))
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => RateModel.fromMap(d.id, d.data())).toList();
  }

  Future<void> addRate(RateModel rate) {
    return _db.collection(FirestoreCollections.rates).add(rate.toMap());
  }

  Future<void> updateRate(RateModel rate) {
    return _db.collection(FirestoreCollections.rates).doc(rate.id).update(rate.toMap());
  }

  Future<void> deleteRate(String rateId) {
    return _db.collection(FirestoreCollections.rates).doc(rateId).delete();
  }

  // ---------------------------------------------------------------------
  // Users (read-only for admin)
  // ---------------------------------------------------------------------

  Future<void> upsertAppUser(AppUserModel user) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Cities this device's user wants to follow — read by the
  /// notify-on-rate-update Cloud Function (`preferredCityIds
  /// array-contains cityId`) to decide who gets pushed a notification.
  /// A targeted merge-set so it never clobbers other user fields (unlike
  /// [upsertAppUser], which is called on every heartbeat and would
  /// otherwise overwrite this with its default empty value).
  Future<void> updatePreferredCities(String uid, List<String> cityIds) {
    return _db.collection(FirestoreCollections.users).doc(uid).set(
      {'preferredCityIds': cityIds},
      SetOptions(merge: true),
    );
  }

  /// This device's current FCM token, kept in sync so the Cloud Function
  /// knows where to deliver push notifications.
  Future<void> updateFcmToken(String uid, String? token) {
    return _db.collection(FirestoreCollections.users).doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  Stream<List<AppUserModel>> watchUsers() {
    return _db
        .collection(FirestoreCollections.users)
        .orderBy('lastSeenAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppUserModel.fromMap(d.id, d.data())).toList());
  }

  // ---------------------------------------------------------------------
  // News feed
  // ---------------------------------------------------------------------

  Stream<List<NewsModel>> watchNews({int limit = 30}) {
    return _db
        .collection(FirestoreCollections.news)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NewsModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> addNews(NewsModel news) {
    return _db.collection(FirestoreCollections.news).add(news.toMap());
  }

  Future<void> updateNews(NewsModel news) {
    return _db.collection(FirestoreCollections.news).doc(news.id).update(news.toMap());
  }

  Future<void> deleteNews(String newsId) {
    return _db.collection(FirestoreCollections.news).doc(newsId).delete();
  }

  // ---------------------------------------------------------------------
  // App config: first-launch onboarding copy + force-update gate.
  // Both are single fixed docs under the `appConfig` collection.
  // ---------------------------------------------------------------------

  /// Welcome-screen and city-selection copy. Returns the all-empty default
  /// (never throws) if the doc doesn't exist yet or the read fails —
  /// callers fall back to a translation-key default in that case.
  Future<AppOnboardingContent> fetchOnboardingContent() async {
    try {
      final doc = await _db.collection(FirestoreCollections.appConfig).doc('onboarding').get();
      if (!doc.exists) return const AppOnboardingContent();
      return AppOnboardingContent.fromMap(doc.data() ?? {});
    } catch (_) {
      return const AppOnboardingContent();
    }
  }

  Future<void> updateOnboardingContent(AppOnboardingContent content) {
    return _db
        .collection(FirestoreCollections.appConfig)
        .doc('onboarding')
        .set(content.toMap(), SetOptions(merge: true));
  }

  /// Force-update gate config. Returns the "gate disabled" default (never
  /// throws, and bounded by a short timeout) so an offline device or a
  /// missing doc never blocks the app from starting — see
  /// AppVersionConfig's doc comment for why this is developer-edited
  /// rather than exposed in the admin UI.
  Future<AppVersionConfig> fetchVersionConfig() async {
    try {
      final doc = await _db
          .collection(FirestoreCollections.appConfig)
          .doc('version')
          .get()
          .timeout(const Duration(seconds: 6));
      if (!doc.exists) {
        debugPrint('fetchVersionConfig: appConfig/version doc does not exist — gate disabled');
        return const AppVersionConfig();
      }
      final config = AppVersionConfig.fromMap(doc.data() ?? {});
      debugPrint(
        'fetchVersionConfig: minBuildNumberAndroid=${config.minBuildNumberAndroid} '
        'minBuildNumberIos=${config.minBuildNumberIos}',
      );
      return config;
    } catch (e) {
      // Logged rather than swallowed silently — a permission-denied here
      // (missing/undeployed Firestore rule for appConfig) or a timeout
      // both look identical to "force update isn't working" from the UI,
      // so this is the one place that tells them apart.
      debugPrint('fetchVersionConfig failed, gate disabled: $e');
      return const AppVersionConfig();
    }
  }
}
