import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchCenterColors {
  const MatchCenterColors._();

  static const pitchBlack = Color(0xFF080C09);
  static const panel = Color(0xFF0B120E);
  static const panelAlt = Color(0xFF0A100C);
  static const panelRaised = Color(0xFF0D1410);
  static const featuredTop = Color(0xFF17331F);
  static const featuredBottom = Color(0xFF090E0B);
  static const border = Color(0xFF17231B);
  static const borderBright = Color(0xFF1F3126);
  static const lime = Color(0xFFC6F24E);
  static const grass = Color(0xFF34A85C);
  static const grassDeep = Color(0xFF17693A);
  static const muted = Color(0xFF6F8877);
  static const textMuted = Color(0xFF7E9686);
  static const textSoft = Color(0xFF8FA697);
  static const offWhite = Color(0xFFE8F3EA);
  static const danger = Color(0xFFE24C4C);
  static const caution = Color(0xFFF2C94C);
}

class MatchCenterTypography {
  const MatchCenterTypography._();

  static TextStyle display({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = MatchCenterColors.offWhite,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.oswald(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle body({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = MatchCenterColors.textSoft,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.chivo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle label({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color color = MatchCenterColors.textSoft,
    double? letterSpacing = 1.1,
  }) {
    return GoogleFonts.chivo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}
