import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String titleEn;
  final String titleUr;
  final String bodyEn;
  final String bodyUr;
  final String? imageUrl;
  final DateTime createdAt;

  const NewsModel({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.bodyEn,
    required this.bodyUr,
    required this.createdAt,
    this.imageUrl,
  });

  String title(String languageCode) => languageCode == 'ur' ? titleUr : titleEn;
  String body(String languageCode) => languageCode == 'ur' ? bodyUr : bodyEn;

  factory NewsModel.fromMap(String id, Map<String, dynamic> map) {
    return NewsModel(
      id: id,
      titleEn: map['titleEn'] as String? ?? '',
      titleUr: map['titleUr'] as String? ?? '',
      bodyEn: map['bodyEn'] as String? ?? '',
      bodyUr: map['bodyUr'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
