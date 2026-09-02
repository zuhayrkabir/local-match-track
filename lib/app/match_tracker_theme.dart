import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/match_center_tokens.dart';

class MatchTrackerTheme {
  static ThemeData get theme {
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
      brightness: Brightness.dark,
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
        color: MatchCenterColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: MatchCenterColors.panelRaised,
        disabledColor: MatchCenterColors.border,
        selectedColor: MatchCenterColors.lime.withValues(alpha: 0.18),
        secondarySelectedColor: MatchCenterColors.grass.withValues(alpha: 0.2),
        labelStyle: MatchCenterTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MatchCenterColors.offWhite,
        ),
        secondaryLabelStyle: MatchCenterTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: MatchCenterColors.lime,
        ),
        side: const BorderSide(color: MatchCenterColors.borderBright),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerTheme: DividerThemeData(
        color: MatchCenterColors.borderBright,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MatchCenterColors.panelRaised,
        labelStyle: MatchCenterTypography.label(
          fontSize: 12,
          color: MatchCenterColors.textSoft,
        ),
        floatingLabelStyle: MatchCenterTypography.label(
          fontSize: 12,
          color: MatchCenterColors.lime,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: MatchCenterColors.borderBright),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: MatchCenterColors.lime,
            width: 1.4,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: MatchCenterColors.border.withValues(alpha: 0.65),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: MatchCenterColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MatchCenterColors.textMuted.withValues(alpha: 0.18);
            }
            if (states.contains(WidgetState.pressed)) {
              return MatchCenterColors.grass;
            }
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFDFFF70);
            }
            return MatchCenterColors.lime;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MatchCenterColors.textMuted;
            }
            return MatchCenterColors.pitchBlack;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MatchCenterColors.offWhite,
          side: const BorderSide(color: MatchCenterColors.borderBright),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return MatchCenterColors.lime;
            }
            return MatchCenterColors.panelRaised;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return MatchCenterColors.pitchBlack;
            }
            if (states.contains(WidgetState.disabled)) {
              return MatchCenterColors.textMuted;
            }
            return MatchCenterColors.offWhite;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: MatchCenterColors.borderBright),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: MatchCenterColors.offWhite,
        iconColor: MatchCenterColors.lime,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
