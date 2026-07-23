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

    final color =
        brightness == Brightness.dark ? Colors.white : const Color(0xFF14211D);

    return base.apply(bodyColor: color, displayColor: color);
  }

  static TextStyle sectionTitle(String languageCode, {Color? color}) {
    final isUrdu = languageCode == 'ur';
    final style = isUrdu
        ? GoogleFonts.notoNastaliqUrdu(fontSize: 20, fontWeight: FontWeight.w600)
        : GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600);
    return color != null ? style.copyWith(color: color) : style;
  }
}
