import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/city_model.dart';
import '../models/rate_model.dart';
import '../models/app_user_model.dart';
import '../models/news_model.dart';

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

  /// Latest rate per city for a given category (used on the rates & dashboard screens).
  Stream<List<RateModel>> watchLatestRatesForCategory(RateCategory category) {
    return _db
        .collection(FirestoreCollections.rates)
        .where('category', isEqualTo: category.key)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) {
      final rates = snap.docs.map((d) => RateModel.fromMap(d.id, d.data())).toList();
      final latestByCity = <String, RateModel>{};
      for (final r in rates) {
        if (!latestByCity.containsKey(r.cityId)) {
          latestByCity[r.cityId] = r;
        }
      }
      final result = latestByCity.values.toList();
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
}
