import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// A single rate entry. Every admin update creates a *new* document rather
/// than overwriting the previous one — this gives us a free price history
/// per city/category that powers the trend graphs, and lets admins delete
/// a single mistaken entry without losing the rest of the history.
class RateModel {
  final String id;
  final RateCategory category;
  final String cityId;
  final String cityNameEn;
  final String cityNameUr;
  final double price;
  final String unit;
  final DateTime date;
  final String? updatedByUid;

  const RateModel({
    required this.id,
    required this.category,
    required this.cityId,
    required this.cityNameEn,
    required this.cityNameUr,
    required this.price,
    required this.unit,
    required this.date,
    this.updatedByUid,
  });

  String cityName(String languageCode) => languageCode == 'ur' ? cityNameUr : cityNameEn;

  factory RateModel.fromMap(String id, Map<String, dynamic> map) {
    return RateModel(
      id: id,
      category: RateCategoryX.fromKey(map['category'] as String? ?? 'chicken'),
      cityId: map['cityId'] as String? ?? '',
      cityNameEn: map['cityNameEn'] as String? ?? '',
      cityNameUr: map['cityNameUr'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedByUid: map['updatedByUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category.key,
      'cityId': cityId,
      'cityNameEn': cityNameEn,
      'cityNameUr': cityNameUr,
      'price': price,
      'unit': unit,
      'date': Timestamp.fromDate(date),
      'updatedByUid': updatedByUid,
    };
  }
}
