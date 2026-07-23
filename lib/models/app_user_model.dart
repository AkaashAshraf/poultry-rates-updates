import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an app visitor. Regular users never see a login screen — on
/// first launch we sign them in anonymously (silently, in the background)
/// purely so the admin can see how many people are using the app and when
/// they were last active. No personal data is collected.
class AppUserModel {
  final String uid;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;
  final String platform;
  final String preferredLanguage;
  final bool isAdmin;
  final String? phoneNumber;

  const AppUserModel({
    required this.uid,
    this.firstSeenAt,
    this.lastSeenAt,
    this.platform = 'unknown',
    this.preferredLanguage = 'en',
    this.isAdmin = false,
    this.phoneNumber,
  });

  factory AppUserModel.fromMap(String uid, Map<String, dynamic> map) {
    return AppUserModel(
      uid: uid,
      firstSeenAt: (map['firstSeenAt'] as Timestamp?)?.toDate(),
      lastSeenAt: (map['lastSeenAt'] as Timestamp?)?.toDate(),
      platform: map['platform'] as String? ?? 'unknown',
      preferredLanguage: map['preferredLanguage'] as String? ?? 'en',
      isAdmin: map['isAdmin'] as bool? ?? false,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstSeenAt': firstSeenAt != null ? Timestamp.fromDate(firstSeenAt!) : FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'platform': platform,
      'preferredLanguage': preferredLanguage,
      'isAdmin': isAdmin,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}
