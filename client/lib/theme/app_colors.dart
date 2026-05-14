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
  static const Color lightSurface = Color(0xFFF7F8FF);  // panels / sidebars – very subtle tint
  static const Color lightCard = Color(0xFFFFFFFF);     // cards – pure white, elevated above surface
  static const Color lightBorder = Color(0xFFDEE1F0);
  static const Color lightText = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF71717A);
  static const Color lightTextHint = Color(0xFFA1A1AA);

  // Dark theme
  static const Color darkBg = Color(0xFF070C18);        // scaffold – noticeably darker than surface
  static const Color darkSurface = Color(0xFF0F172A);   // panels – was old darkBg
  static const Color darkCard = Color(0xFF192437);      // cards – lighter than surface
  static const Color darkBorder = Color(0xFF243247);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFB8C2D9);
  static const Color darkTextHint = Color(0xFF7B8AA8);

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
