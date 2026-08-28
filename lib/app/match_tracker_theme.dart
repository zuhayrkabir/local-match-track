import 'package:flutter/material.dart';

class MatchTrackerTheme {
  static const _grassGreen = Color(0xFF1B7F3A);
  static const _deepPitch = Color(0xFF064E2B);
  static const _lineWhite = Color(0xFFF8FAF6);
  static const _nightPitch = Color(0xFF071A12);
  static const _floodlight = Color(0xFFE7F8D8);

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
      seedColor: _grassGreen,
      brightness: Brightness.dark,
      primary: _floodlight,
      secondary: const Color(0xFF7DDE92),
      surface: const Color(0xFF10271B),
    );

    return _baseTheme(scheme).copyWith(
      scaffoldBackgroundColor: _nightPitch,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: _nightPitch,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
    );
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
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
