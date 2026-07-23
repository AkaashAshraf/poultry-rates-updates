import 'package:flutter/material.dart';

/// Central brand palette for the Poultry Rates app.
///
/// Palette story: a fresh agricultural teal/green as the primary brand color
/// (trust, freshness) paired with a warm amber accent (energy, eggs/chicken)
/// and a rustic red used only to tag the "meat" category. This keeps the
/// UI calm and professional while still giving each rate category (chicken,
/// meat, egg) an instantly recognizable color.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0E6E55); // deep teal green
  static const Color primaryLight = Color(0xFF3E9B7F);
  static const Color primaryDark = Color(0xFF063D2F);

  static const Color accent = Color(0xFFF5A623); // warm amber
  static const Color accentDark = Color(0xFFC97F0A);

  // Category tags
  static const Color chicken = Color(0xFFF08A24); // warm orange
  static const Color meat = Color(0xFFC0392B); // rustic red
  static const Color egg = Color(0xFFE0A800); // golden yellow

  // Neutrals — light theme
  static const Color backgroundLight = Color(0xFFF6F8F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF14211D);
  static const Color textSecondaryLight = Color(0xFF5C6B66);
  static const Color borderLight = Color(0xFFE1E7E4);

  // Neutrals — dark theme
  static const Color backgroundDark = Color(0xFF0E1512);
  static const Color surfaceDark = Color(0xFF162019);
  static const Color textPrimaryDark = Color(0xFFEDF3F0);
  static const Color textSecondaryDark = Color(0xFFA3B3AD);
  static const Color borderDark = Color(0xFF2A3730);

  // Status
  static const Color success = Color(0xFF2E9E5B);
  static const Color error = Color(0xFFD64545);
  static const Color warning = Color(0xFFE0A800);
  static const Color info = Color(0xFF3283C4);

  static const List<Color> splashGradient = [primaryDark, primary, primaryLight];
}
