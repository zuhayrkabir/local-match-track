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
      visualDensity: VisualDensity.standard,
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
      dialogTheme: DialogThemeData(
        backgroundColor: MatchCenterColors.panel,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: MatchCenterTypography.body(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: MatchCenterColors.offWhite,
        ),
        contentTextStyle: MatchCenterTypography.body(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: MatchCenterColors.offWhite,
          height: 1.45,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: MatchCenterColors.panelRaised,
        contentTextStyle: MatchCenterTypography.body(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: MatchCenterColors.offWhite,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: MatchCenterColors.panelRaised,
          border: Border.all(color: MatchCenterColors.borderBright),
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: MatchCenterTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MatchCenterColors.offWhite,
        ),
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
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          tapTargetSize: MaterialTapTargetSize.padded,
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          textStyle: WidgetStateProperty.all(
            MatchCenterTypography.label(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: MatchCenterColors.pitchBlack,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MatchCenterColors.textMuted;
            }
            if (states.contains(WidgetState.pressed)) {
              return MatchCenterColors.lime;
            }
            return MatchCenterColors.offWhite;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return MatchCenterColors.lime.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: MatchCenterColors.border.withValues(alpha: 0.65),
              );
            }
            if (states.contains(WidgetState.focused) ||
                states.contains(WidgetState.hovered)) {
              return const BorderSide(
                color: MatchCenterColors.lime,
                width: 1.4,
              );
            }
            return const BorderSide(color: MatchCenterColors.borderBright);
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          ),
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          tapTargetSize: MaterialTapTargetSize.padded,
          overlayColor: WidgetStateProperty.all(
            MatchCenterColors.lime.withValues(alpha: 0.12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          textStyle: WidgetStateProperty.all(
            MatchCenterTypography.label(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: MatchCenterColors.offWhite,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MatchCenterColors.textMuted;
            }
            return MatchCenterColors.lime;
          }),
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          tapTargetSize: MaterialTapTargetSize.padded,
          overlayColor: WidgetStateProperty.all(
            MatchCenterColors.lime.withValues(alpha: 0.12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: WidgetStateProperty.all(
            MatchCenterTypography.label(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: MatchCenterColors.lime,
            ),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return MatchCenterColors.textMuted;
            }
            if (states.contains(WidgetState.pressed)) {
              return MatchCenterColors.pitchBlack;
            }
            return MatchCenterColors.offWhite;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return MatchCenterColors.lime;
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return MatchCenterColors.lime.withValues(alpha: 0.12);
            }
            return Colors.transparent;
          }),
          minimumSize: WidgetStateProperty.all(const Size.square(48)),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          minimumSize: WidgetStateProperty.all(const Size(64, 48)),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: MatchCenterColors.lime,
        unselectedLabelColor: MatchCenterColors.textSoft,
        indicatorColor: MatchCenterColors.lime,
        dividerColor: MatchCenterColors.border,
        labelStyle: MatchCenterTypography.label(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: MatchCenterColors.lime,
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
