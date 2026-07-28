import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Picks the right font family for the active locale.
///
/// English (and any non-Urdu locale) uses Poppins for a clean, modern,
/// geometric look. Urdu uses Noto Nastaliq Urdu, which renders proper
/// Nastaliq script — far more readable than a generic sans font for Urdu
/// readers.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(String languageCode, Brightness brightness) {
    final isUrdu = languageCode == 'ur';
    final base = isUrdu
        ? GoogleFonts.notoNastaliqUrduTextTheme()
        : GoogleFonts.poppinsTextTheme();

    final color = brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF14211D);

    // Noto Nastaliq Urdu renders visibly larger than Poppins at the same
    // declared font size — tall, sloping Nastaliq strokes plus diacritics
    // give it a bigger footprint — which made Urdu screens look oversized
    // and cramped next to the English ones. Scale every Urdu size down a
    // bit to match the visual weight of the English text.
    //
    // Deliberately not using TextTheme.apply(fontSizeFactor: ...) for this:
    // it applies to every style in the theme unconditionally, and asserts
    // if any of them has a null fontSize — which at least one style in
    // notoNastaliqUrduTextTheme() does, crashing the app on launch.
    // _scaleFontSize skips null-fontSize styles instead of asserting.
    final sized = isUrdu ? _scaleFontSize(base, 0.62) : base;

    return sized.apply(bodyColor: color, displayColor: color);
  }

  static TextTheme _scaleFontSize(TextTheme theme, double factor) {
    TextStyle? scale(TextStyle? style) {
      if (style == null || style.fontSize == null) return style;
      return style.copyWith(fontSize: style.fontSize! * factor);
    }

    return theme.copyWith(
      displayLarge: scale(theme.displayLarge),
      displayMedium: scale(theme.displayMedium),
      displaySmall: scale(theme.displaySmall),
      headlineLarge: scale(theme.headlineLarge),
      headlineMedium: scale(theme.headlineMedium),
      headlineSmall: scale(theme.headlineSmall),
      titleLarge: scale(theme.titleLarge),
      titleMedium: scale(theme.titleMedium),
      titleSmall: scale(theme.titleSmall),
      bodyLarge: scale(theme.bodyLarge),
      bodyMedium: scale(theme.bodyMedium),
      bodySmall: scale(theme.bodySmall),
      labelLarge: scale(theme.labelLarge),
      labelMedium: scale(theme.labelMedium),
      labelSmall: scale(theme.labelSmall),
    );
  }

  static TextStyle sectionTitle(String languageCode, {Color? color}) {
    final isUrdu = languageCode == 'ur';
    final style = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          )
        : GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600);
    return color != null ? style.copyWith(color: color) : style;
  }
}
