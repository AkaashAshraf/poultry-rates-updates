import 'package:cloud_firestore/cloud_firestore.dart';

class CityModel {
  final String id;
  final String nameEn;
  final String nameUr;
  final bool isActive;
  final DateTime? createdAt;

  const CityModel({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    this.isActive = true,
    this.createdAt,
  });

  String localizedName(String languageCode) =>
      languageCode == 'ur' ? nameUr : nameEn;

  factory CityModel.fromMap(String id, Map<String, dynamic> map) {
    return CityModel(
      id: id,
      nameEn: map['nameEn'] as String? ?? '',
      nameUr: map['nameUr'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameEn': nameEn,
      'nameUr': nameUr,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  CityModel copyWith({
    String? nameEn,
    String? nameUr,
    bool? isActive,
  }) {
    return CityModel(
      id: id,
      nameEn: nameEn ?? this.nameEn,
      nameUr: nameUr ?? this.nameUr,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
