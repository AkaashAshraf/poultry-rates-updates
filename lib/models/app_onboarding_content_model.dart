/// Admin-editable copy shown on the first-launch welcome screen and above
/// the city-selection step. Lives at Firestore doc `appConfig/onboarding`.
///
/// Every field defaults to an empty string when the doc doesn't exist yet
/// (fresh Firestore project, admin hasn't opened the editor) — screens that
/// read this fall back to a translation-key default in that case, so a
/// missing doc never means a blank screen.
class AppOnboardingContent {
  final String welcomeTitleEn;
  final String welcomeTitleUr;
  final String welcomeMessageEn;
  final String welcomeMessageUr;
  final String citySelectionDescriptionEn;
  final String citySelectionDescriptionUr;

  const AppOnboardingContent({
    this.welcomeTitleEn = '',
    this.welcomeTitleUr = '',
    this.welcomeMessageEn = '',
    this.welcomeMessageUr = '',
    this.citySelectionDescriptionEn = '',
    this.citySelectionDescriptionUr = '',
  });

  String welcomeTitle(String languageCode) => languageCode == 'ur' ? welcomeTitleUr : welcomeTitleEn;
  String welcomeMessage(String languageCode) => languageCode == 'ur' ? welcomeMessageUr : welcomeMessageEn;
  String citySelectionDescription(String languageCode) =>
      languageCode == 'ur' ? citySelectionDescriptionUr : citySelectionDescriptionEn;

  factory AppOnboardingContent.fromMap(Map<String, dynamic> map) {
    return AppOnboardingContent(
      welcomeTitleEn: map['welcomeTitleEn'] as String? ?? '',
      welcomeTitleUr: map['welcomeTitleUr'] as String? ?? '',
      welcomeMessageEn: map['welcomeMessageEn'] as String? ?? '',
      welcomeMessageUr: map['welcomeMessageUr'] as String? ?? '',
      citySelectionDescriptionEn: map['citySelectionDescriptionEn'] as String? ?? '',
      citySelectionDescriptionUr: map['citySelectionDescriptionUr'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'welcomeTitleEn': welcomeTitleEn,
      'welcomeTitleUr': welcomeTitleUr,
      'welcomeMessageEn': welcomeMessageEn,
      'welcomeMessageUr': welcomeMessageUr,
      'citySelectionDescriptionEn': citySelectionDescriptionEn,
      'citySelectionDescriptionUr': citySelectionDescriptionUr,
    };
  }
}
