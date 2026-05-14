import 'package:flutter/material.dart';

class AppColors {
  // Primary – Indigo/Violet
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primarySurface = Color(0xFFEEF2FF);

  // Accent – Teal
  static const Color accent = Color(0xFF0891B2);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Light theme
  static const Color lightBg = Color(0xFFEEF1FF);       // scaffold background – visible indigo tint
  static const Color lightBgGlow = Color(0xFFE0F2FE);   // soft cyan glow for gradient depth
  static const Color lightBgWarm = Color(0xFFF7F0FF);   // soft violet glow for gradient depth
  static const Color lightSurface = Color(0xFFF7F8FF);  // panels / sidebars – very subtle tint
  static const Color lightCard = Color(0xFFFFFFFF);     // cards – pure white, elevated above surface
  static const Color lightBorder = Color(0xFFDEE1F0);
  static const Color lightText = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF71717A);
  static const Color lightTextHint = Color(0xFFA1A1AA);

  // Dark theme
  static const Color darkBg = Color(0xFF070C18);        // scaffold – noticeably darker than surface
  static const Color darkBgGlow = Color(0xFF111C3A);    // firm indigo glow for gradient depth
  static const Color darkBgTeal = Color(0xFF082633);    // restrained teal glow for gradient depth
  static const Color darkSurface = Color(0xFF0F172A);   // panels – was old darkBg
  static const Color darkCard = Color(0xFF192437);      // cards – lighter than surface
  static const Color darkBorder = Color(0xFF243247);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFB8C2D9);
  static const Color darkTextHint = Color(0xFF7B8AA8);

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBFCFF),
      lightBgGlow,
      lightBg,
      lightBgWarm,
    ],
    stops: [0.0, 0.32, 0.68, 1.0],
  );

  static const LinearGradient glassLightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAFCFF),
      Color(0xFFDFF8FF),
      Color(0xFFEAE7FF),
      Color(0xFFFFF1F8),
    ],
    stops: [0.0, 0.30, 0.66, 1.0],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkBgGlow,
      darkBg,
      Color(0xFF0B1428),
      darkBgTeal,
    ],
    stops: [0.0, 0.36, 0.70, 1.0],
  );

  static const LinearGradient glassDarkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF121B3F),
      Color(0xFF050A16),
      Color(0xFF10172F),
      Color(0xFF052B37),
    ],
    stops: [0.0, 0.34, 0.68, 1.0],
  );

  static LinearGradient backgroundGradient(
    Brightness brightness, {
    bool glassMode = false,
  }) {
    if (glassMode) {
      return brightness == Brightness.dark
          ? glassDarkBackgroundGradient
          : glassLightBackgroundGradient;
    }
    return brightness == Brightness.dark
        ? darkBackgroundGradient
        : lightBackgroundGradient;
  }

  // Node colors
  static const Color nodeStart = Color(0xFF16A34A);
  static const Color nodeEnd = Color(0xFFDC2626);
  static const Color nodeStep = Color(0xFF4F46E5);
  static const Color nodeDecision = Color(0xFFD97706);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF4F46E5),
    Color(0xFF0891B2),
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
  ];
}
