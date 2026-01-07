/// SYSTEM Theme Configuration
///
/// Deep Space Dark Mode + Clean Light Mode with Glassmorphism aesthetic.
/// Design tokens for the "Hacker Console meets Premium SaaS" look.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme mode enum
enum SystemThemeMode { dark, light, system }

/// Core color palette for SYSTEM app
class SystemColors {
  SystemColors._();

  // ============ DARK MODE COLORS ============
  // Background colors
  static const Color backgroundDark = Color(0xFF0F0F13);
  static const Color backgroundLightDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1A1A1F);
  static const Color surfaceElevatedDark = Color(0xFF222228);

  // ============ LIGHT MODE COLORS ============
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundLightLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF0F1F3);

  // ============ ACCENT COLORS (shared) ============
  static const Color neonGreen = Color(0xFF00FF9D);
  static const Color neonGreenDim = Color(0xFF00CC7D);
  static const Color neonGreenLight = Color(0xFF00D68F); // Slightly adjusted for light mode
  static const Color electricPurple = Color(0xFFBB86FC);
  static const Color electricPurpleDim = Color(0xFF9966DD);
  static const Color electricPurpleLight = Color(0xFF9C5EF8);

  // Semantic colors
  static const Color success = neonGreen;
  static const Color processing = electricPurple;
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorLight = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB86C);
  static const Color info = Color(0xFF64B5F6);

  // ============ TEXT COLORS ============
  // Dark mode
  static const Color textPrimaryDark = Color(0xFFE8E8E8);
  static const Color textSecondaryDark = Color(0xFF8B8B8B);
  static const Color textMutedDark = Color(0xFF5A5A5A);

  // Light mode
  static const Color textPrimaryLight = Color(0xFF1A1A1F);
  static const Color textSecondaryLight = Color(0xFF5A5A5A);
  static const Color textMutedLight = Color(0xFF9E9E9E);

  // ============ GLASS EFFECT COLORS ============
  // Dark mode
  static const Color glassBackgroundDark = Color(0x1AFFFFFF);
  static const Color glassBorderDark = Color(0x33FFFFFF);
  static const Color glassHighlightDark = Color(0x0DFFFFFF);

  // Light mode
  static const Color glassBackgroundLight = Color(0x80FFFFFF);
  static const Color glassBorderLight = Color(0x40000000);
  static const Color glassHighlightLight = Color(0x20000000);

  // Chart colors
  static const Color chartCpu = neonGreen;
  static const Color chartRam = electricPurple;
  static const Color chartGridDark = Color(0xFF2A2A30);
  static const Color chartGridLight = Color(0xFFE0E0E0);

  // ============ LEGACY NAMES (for compatibility) ============
  static const Color background = backgroundDark;
  static const Color surface = surfaceDark;
  static const Color surfaceElevated = surfaceElevatedDark;
  static const Color textPrimary = textPrimaryDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textMuted = textMutedDark;
  static const Color glassBackground = glassBackgroundDark;
  static const Color glassBorder = glassBorderDark;
  static const Color glassHighlight = glassHighlightDark;
  static const Color chartGrid = chartGridDark;
}

/// Dynamic colors that change based on theme
class DynamicColors {
  final bool isDark;

  const DynamicColors({required this.isDark});

  Color get background =>
      isDark ? SystemColors.backgroundDark : SystemColors.backgroundLight;
  Color get surface =>
      isDark ? SystemColors.surfaceDark : SystemColors.surfaceLight;
  Color get surfaceElevated =>
      isDark ? SystemColors.surfaceElevatedDark : SystemColors.surfaceElevatedLight;
  Color get textPrimary =>
      isDark ? SystemColors.textPrimaryDark : SystemColors.textPrimaryLight;
  Color get textSecondary =>
      isDark ? SystemColors.textSecondaryDark : SystemColors.textSecondaryLight;
  Color get textMuted =>
      isDark ? SystemColors.textMutedDark : SystemColors.textMutedLight;
  Color get glassBackground =>
      isDark ? SystemColors.glassBackgroundDark : SystemColors.glassBackgroundLight;
  Color get glassBorder =>
      isDark ? SystemColors.glassBorderDark : SystemColors.glassBorderLight;
  Color get chartGrid =>
      isDark ? SystemColors.chartGridDark : SystemColors.chartGridLight;
  Color get accent =>
      isDark ? SystemColors.neonGreen : SystemColors.neonGreenLight;
  Color get accentSecondary =>
      isDark ? SystemColors.electricPurple : SystemColors.electricPurpleLight;
  Color get error =>
      isDark ? SystemColors.error : SystemColors.errorLight;
}

/// Text styles using JetBrains Mono and Inter
class SystemTextStyles {
  SystemTextStyles._();

  // JetBrains Mono for terminal/data display (static getters for default dark theme)
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        color: SystemColors.textPrimaryDark,
      );

  static TextStyle get monoSmall => mono.copyWith(fontSize: 12);
  static TextStyle get monoMedium => mono.copyWith(fontSize: 14);
  static TextStyle get monoLarge => mono.copyWith(fontSize: 16);
  static TextStyle get monoXLarge => mono.copyWith(fontSize: 20, fontWeight: FontWeight.w600);

  // Inter for UI elements (static getters for default dark theme)
  static TextStyle get ui => GoogleFonts.inter(
        color: SystemColors.textPrimaryDark,
      );

  static TextStyle get uiSmall => ui.copyWith(fontSize: 12);
  static TextStyle get uiMedium => ui.copyWith(fontSize: 14);
  static TextStyle get uiLarge => ui.copyWith(fontSize: 16);
  static TextStyle get uiXLarge => ui.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get uiHeadline => ui.copyWith(fontSize: 24, fontWeight: FontWeight.bold);

  // Label styles
  static TextStyle get labelSmall => uiSmall.copyWith(
        color: SystemColors.textMutedDark,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => uiMedium.copyWith(
        color: SystemColors.textSecondaryDark,
        fontWeight: FontWeight.w500,
      );
}

/// Spacing constants
class SystemSpacing {
  SystemSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
}

/// Border radius constants
class SystemRadius {
  SystemRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
}

/// Theme provider for managing theme state
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  DynamicColors get colors => DynamicColors(isDark: isDark);
}

/// Main theme data builder
class SystemTheme {
  SystemTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SystemColors.backgroundDark,
      primaryColor: SystemColors.neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: SystemColors.neonGreen,
        secondary: SystemColors.electricPurple,
        surface: SystemColors.surfaceDark,
        error: SystemColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: SystemTextStyles.uiHeadline,
        displayMedium: SystemTextStyles.uiXLarge,
        displaySmall: SystemTextStyles.uiLarge,
        headlineMedium: SystemTextStyles.uiXLarge,
        titleLarge: SystemTextStyles.uiLarge,
        titleMedium: SystemTextStyles.uiMedium,
        bodyLarge: SystemTextStyles.uiMedium,
        bodyMedium: SystemTextStyles.uiSmall,
        labelLarge: SystemTextStyles.labelMedium,
        labelMedium: SystemTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: SystemTextStyles.monoLarge.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      cardTheme: CardThemeData(
        color: SystemColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: SystemRadius.borderMd,
        ),
      ),
      iconTheme: const IconThemeData(
        color: SystemColors.textSecondaryDark,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: SystemColors.surfaceElevatedDark,
        thickness: 1,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: SystemColors.backgroundLight,
      primaryColor: SystemColors.neonGreenLight,
      colorScheme: const ColorScheme.light(
        primary: SystemColors.neonGreenLight,
        secondary: SystemColors.electricPurpleLight,
        surface: SystemColors.surfaceLight,
        error: SystemColors.errorLight,
      ),
      textTheme: TextTheme(
        displayLarge:
            SystemTextStyles.uiHeadline.copyWith(color: SystemColors.textPrimaryLight),
        displayMedium:
            SystemTextStyles.uiXLarge.copyWith(color: SystemColors.textPrimaryLight),
        displaySmall:
            SystemTextStyles.uiLarge.copyWith(color: SystemColors.textPrimaryLight),
        headlineMedium:
            SystemTextStyles.uiXLarge.copyWith(color: SystemColors.textPrimaryLight),
        titleLarge:
            SystemTextStyles.uiLarge.copyWith(color: SystemColors.textPrimaryLight),
        titleMedium:
            SystemTextStyles.uiMedium.copyWith(color: SystemColors.textPrimaryLight),
        bodyLarge:
            SystemTextStyles.uiMedium.copyWith(color: SystemColors.textPrimaryLight),
        bodyMedium:
            SystemTextStyles.uiSmall.copyWith(color: SystemColors.textPrimaryLight),
        labelLarge:
            SystemTextStyles.labelMedium.copyWith(color: SystemColors.textSecondaryLight),
        labelMedium:
            SystemTextStyles.labelSmall.copyWith(color: SystemColors.textMutedLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle:
            SystemTextStyles.monoLarge.copyWith(
          color: SystemColors.textPrimaryLight,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        iconTheme: const IconThemeData(color: SystemColors.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: SystemColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: SystemRadius.borderMd,
          side: BorderSide(color: SystemColors.surfaceElevatedLight),
        ),
      ),
      iconTheme: const IconThemeData(
        color: SystemColors.textSecondaryLight,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: SystemColors.surfaceElevatedLight,
        thickness: 1,
      ),
    );
  }
}
