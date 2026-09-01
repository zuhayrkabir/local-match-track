import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/match_center_tokens.dart';

class MatchTrackerTheme {
  static const _grassGreen = Color(0xFF1B7F3A);
  static const _deepPitch = Color(0xFF064E2B);
  static const _lineWhite = Color(0xFFF8FAF6);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _grassGreen,
      brightness: Brightness.light,
      primary: _deepPitch,
      secondary: _grassGreen,
      surface: _lineWhite,
    );

    return _baseTheme(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFEAF6EA),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: MatchCenterColors.lime,
      brightness: Brightness.dark,
      primary: MatchCenterColors.lime,
      secondary: MatchCenterColors.grass,
      surface: MatchCenterColors.panel,
    );

    return _baseTheme(scheme).copyWith(
      scaffoldBackgroundColor: MatchCenterColors.pitchBlack,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: MatchCenterColors.pitchBlack,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
    );
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: GoogleFonts.chivoTextTheme().copyWith(
        displayLarge: GoogleFonts.oswald(fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.oswald(fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.oswald(fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.oswald(fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.oswald(fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.oswald(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.chivo(fontWeight: FontWeight.w800),
        titleMedium: GoogleFonts.chivo(fontWeight: FontWeight.w700),
        titleSmall: GoogleFonts.chivo(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
