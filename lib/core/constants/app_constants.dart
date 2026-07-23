import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Firestore collection names, kept in one place so a rename is a one-line change.
class FirestoreCollections {
  FirestoreCollections._();

  static const String cities = 'cities';
  static const String rates = 'rates';
  static const String news = 'news';
  static const String users = 'users';
  static const String admins = 'admins';
}

/// The three rate categories the app tracks.
enum RateCategory { chicken, meat, egg }

extension RateCategoryX on RateCategory {
  String get key {
    switch (this) {
      case RateCategory.chicken:
        return 'chicken';
      case RateCategory.meat:
        return 'meat';
      case RateCategory.egg:
        return 'egg';
    }
  }

  static RateCategory fromKey(String key) {
    return RateCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => RateCategory.chicken,
    );
  }

  Color get color {
    switch (this) {
      case RateCategory.chicken:
        return AppColors.chicken;
      case RateCategory.meat:
        return AppColors.meat;
      case RateCategory.egg:
        return AppColors.egg;
    }
  }

  IconData get icon {
    switch (this) {
      case RateCategory.chicken:
        return Icons.set_meal_outlined;
      case RateCategory.meat:
        return Icons.kebab_dining_outlined;
      case RateCategory.egg:
        return Icons.egg_outlined;
    }
  }

  /// Translation key used with easy_localization, e.g. 'category.chicken'.
  String get labelKey => 'category.$key';

  /// Translation key for the default unit, e.g. 'unit.perKg'.
  String get defaultUnitKey =>
      this == RateCategory.egg ? 'unit.perDozen' : 'unit.perKg';
}

class AppConstants {
  AppConstants._();

  static const String appName = 'Poultry Rates';
  static const String prefsLocaleKey = 'app_locale';
  static const String prefsThemeKey = 'app_theme_mode';
  static const int otpLength = 6;
  static const int otpResendSeconds = 60;
}
