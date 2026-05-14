import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base, Color textColor, Color secondaryColor) {
    final font = GoogleFonts.interTextTheme(base);
    return font.copyWith(
      displayLarge: font.displayLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      displayMedium: font.displayMedium?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      displaySmall: font.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      headlineLarge: font.headlineLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      headlineMedium: font.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      headlineSmall: font.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleLarge: font.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      titleMedium: font.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w500),
      titleSmall: font.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w500),
      bodyLarge: font.bodyLarge?.copyWith(color: textColor),
      bodyMedium: font.bodyMedium?.copyWith(color: textColor),
      bodySmall: font.bodySmall?.copyWith(color: secondaryColor),
      labelLarge: font.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.w500),
      labelMedium: font.labelMedium?.copyWith(color: secondaryColor),
      labelSmall: font.labelSmall?.copyWith(color: secondaryColor),
    );
  }

  static ThemeData light({bool glassMode = false}) {
    final base = ThemeData.light(useMaterial3: true);
    final surface = glassMode ? Colors.white.withValues(alpha: 0.62) : AppColors.lightSurface;
    final card = glassMode ? Colors.white.withValues(alpha: 0.70) : AppColors.lightCard;
    final inputFill = glassMode ? Colors.white.withValues(alpha: 0.46) : AppColors.lightSurface;
    final border = glassMode ? Colors.white.withValues(alpha: 0.58) : AppColors.lightBorder;
    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: card,
        onSurface: AppColors.lightText,
        surfaceContainerHighest: AppColors.lightBg,
        surfaceContainer: surface,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorder.withValues(alpha: 0.5),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      drawerTheme: DrawerThemeData(
        backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.58) : AppColors.lightSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.lightText, AppColors.lightTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightText,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
        actionsIconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
        shape: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.lightTextHint, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.lightTextSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.primary, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: glassMode
              ? AppColors.primary.withValues(alpha: 0.72)
              : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: glassMode ? 8 : 0,
          shadowColor: glassMode
              ? AppColors.primary.withValues(alpha: 0.24)
              : Colors.transparent,
          minimumSize: const Size(0, 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 16 : 12)),
          side: glassMode
              ? BorderSide(color: Colors.white.withValues(alpha: 0.42), width: 1)
              : BorderSide.none,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.34) : null,
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 16 : 12)),
          side: BorderSide(
            color: glassMode ? Colors.white.withValues(alpha: 0.62) : AppColors.primary,
            width: glassMode ? 1.2 : 1.5,
          ),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.18) : null,
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 14 : 8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.42) : AppColors.primarySurface,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
        side: BorderSide(
          color: glassMode ? Colors.white.withValues(alpha: 0.58) : AppColors.primaryLight,
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 999 : 8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: glassMode ? Colors.white.withValues(alpha: 0.50) : AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.20) : null,
          foregroundColor: AppColors.lightText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 14 : 8)),
          side: glassMode
              ? BorderSide(color: Colors.white.withValues(alpha: 0.48), width: 1)
              : BorderSide.none,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.lightText.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightText,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightText,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.lightTextSecondary),
        selectedLabelTextStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: AppColors.lightTextSecondary),
        indicatorColor: AppColors.primarySurface,
        useIndicator: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: glassMode
            ? AppColors.primary.withValues(alpha: 0.76)
            : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: glassMode ? 10 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 18 : 16)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : AppColors.lightTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primarySurface : AppColors.lightBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primary : AppColors.lightTextSecondary),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.lightTextSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
        dividerColor: AppColors.lightBorder,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: glassMode ? Colors.white.withValues(alpha: 0.74) : surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: glassMode ? 0.14 : 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(glassMode ? 18 : 12),
          side: BorderSide(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.62)
                : AppColors.lightBorder,
          ),
        ),
        elevation: glassMode ? 14 : 4,
        textStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.lightText),
      ),
    );
  }

  static ThemeData dark({bool glassMode = false}) {
    final base = ThemeData.dark(useMaterial3: true);
    final surface = glassMode ? Colors.white.withValues(alpha: 0.08) : AppColors.darkSurface;
    final card = glassMode ? Colors.white.withValues(alpha: 0.11) : AppColors.darkCard;
    final inputFill = glassMode ? Colors.white.withValues(alpha: 0.075) : AppColors.darkSurface;
    final border = glassMode ? Colors.white.withValues(alpha: 0.16) : AppColors.darkBorder;
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primary.withValues(alpha: 0.2),
        onPrimaryContainer: AppColors.primarySurface,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: card,
        onSurface: AppColors.darkText,
        surfaceContainerHighest: AppColors.darkBg,
        surfaceContainer: surface,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorder.withValues(alpha: 0.5),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      drawerTheme: DrawerThemeData(
        backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.08) : AppColors.darkSurface,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.darkText, AppColors.darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
        actionsIconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
        shape: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,  // panels/inputs slightly darker than card
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.darkTextHint, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.primaryLight, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: glassMode
              ? AppColors.primaryLight.withValues(alpha: 0.58)
              : AppColors.primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          alignment: Alignment.center,
          elevation: glassMode ? 10 : 0,
          shadowColor: glassMode
              ? AppColors.primaryLight.withValues(alpha: 0.22)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 16 : 12)),
          side: glassMode
              ? BorderSide(color: Colors.white.withValues(alpha: 0.18), width: 1)
              : BorderSide.none,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.07) : null,
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(0, 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 16 : 12)),
          side: BorderSide(
            color: glassMode ? Colors.white.withValues(alpha: 0.18) : AppColors.primaryLight,
            width: glassMode ? 1.2 : 1.5,
          ),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.06) : null,
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(0, 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 14 : 8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glassMode
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
        side: BorderSide(
          color: glassMode
              ? Colors.white.withValues(alpha: 0.16)
              : AppColors.primaryLight.withValues(alpha: 0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 999 : 8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: glassMode ? Colors.white.withValues(alpha: 0.13) : AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: glassMode ? Colors.white.withValues(alpha: 0.06) : null,
          foregroundColor: AppColors.darkText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 14 : 8)),
          side: glassMode
              ? BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1)
              : BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: GoogleFonts.inter(color: AppColors.darkText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryLight),
        unselectedIconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
        selectedLabelTextStyle:
            const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.darkTextSecondary),
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        useIndicator: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: glassMode
            ? AppColors.primaryLight.withValues(alpha: 0.58)
            : AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: glassMode ? 10 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(glassMode ? 18 : 16)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.darkTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: 0.4)
            : AppColors.darkBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryLight : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.darkTextSecondary),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
        dividerColor: AppColors.darkBorder,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: glassMode ? Colors.white.withValues(alpha: 0.10) : card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: glassMode ? 0.36 : 0.22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(glassMode ? 18 : 12),
          side: BorderSide(
            color: glassMode
                ? Colors.white.withValues(alpha: 0.16)
                : AppColors.darkBorder,
          ),
        ),
        elevation: glassMode ? 14 : 4,
        textStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.darkText),
      ),
    );
  }
}

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
