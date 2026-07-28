/// Force-update gate config. Lives at Firestore doc `appConfig/version`.
///
/// Intentionally *not* exposed in an admin UI — the developer edits this
/// directly in the Firebase console when cutting a release that must not
/// be skipped. Fields, to set there:
///
///   minBuildNumberAndroid  (number) — the Android `versionCode` of the
///                                     oldest build still allowed to run.
///   minBuildNumberIos      (number) — the iOS `CFBundleVersion` of the
///                                     oldest build still allowed to run.
///   updateMessageEn        (string, optional)
///   updateMessageUr        (string, optional)
///   playStoreUrl           (string) — opened by the "Update Now" button
///                                     on Android.
///   appStoreUrl            (string) — opened by the "Update Now" button
///                                     on iOS.
///
/// Leave minBuildNumberAndroid/minBuildNumberIos at 0 (or delete the doc
/// entirely) to disable the gate — that's the default, so creating this
/// doc is entirely optional until you actually need to force an update.
class AppVersionConfig {
  final int minBuildNumberAndroid;
  final int minBuildNumberIos;
  final String updateMessageEn;
  final String updateMessageUr;
  final String playStoreUrl;
  final String appStoreUrl;

  const AppVersionConfig({
    this.minBuildNumberAndroid = 0,
    this.minBuildNumberIos = 0,
    this.updateMessageEn = '',
    this.updateMessageUr = '',
    this.playStoreUrl = '',
    this.appStoreUrl = '',
  });

  String updateMessage(String languageCode) => languageCode == 'ur' ? updateMessageUr : updateMessageEn;

  factory AppVersionConfig.fromMap(Map<String, dynamic> map) {
    return AppVersionConfig(
      minBuildNumberAndroid: (map['minBuildNumberAndroid'] as num?)?.toInt() ?? 0,
      minBuildNumberIos: (map['minBuildNumberIos'] as num?)?.toInt() ?? 0,
      updateMessageEn: map['updateMessageEn'] as String? ?? '',
      updateMessageUr: map['updateMessageUr'] as String? ?? '',
      playStoreUrl: map['playStoreUrl'] as String? ?? '',
      appStoreUrl: map['appStoreUrl'] as String? ?? '',
    );
  }
}
