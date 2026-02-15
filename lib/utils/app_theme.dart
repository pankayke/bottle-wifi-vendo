import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BottleWiFi eco recycling design system.
/// Forest green primary + leaf green secondary + lime accents.
class BWColors {
  BWColors._();

  // Primary palette — eco / recycling greens
  static const primary = Color(0xFF2D5A3A); // Forest Green
  static const primaryDark = Color(0xFF1B3A24);
  static const primaryLight = Color(0xFF4CAF50); // Leaf Green

  // Secondary / accent
  static const secondary = Color(0xFF4CAF50); // Leaf Green
  static const accent = Color(0xFF8BC34A); // Lime
  static const accentLight = Color(0xFFC5E1A5);

  // Gradient endpoints (dark green → light green)
  static const gradientStart = Color(0xFF1B3A24); // Dark forest
  static const gradientEnd = Color(0xFF4CAF50); // Leaf green

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // Text
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);

  // Surface
  static const background = Color(0xFFF1F8E9); // Light green tint
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE8F5E9);
  static const divider = Color(0xFFE2E8F0);

  // Hero gradient
  static const heroGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [secondary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Spacing / sizing tokens.
class BWSpacing {
  BWSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double cardRadius = 20;
  static const double buttonRadius = 14;
  static const double inputRadius = 12;

  static const double cardElevation = 4;
  static const double maxContentWidth = 520;
}

/// Centralized Poppins-based text theme.
class BWTextTheme {
  BWTextTheme._();

  static TextTheme get textTheme => GoogleFonts.poppinsTextTheme(
    const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: BWColors.textPrimary,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: BWColors.textPrimary,
        height: 1.25,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: BWColors.textPrimary,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: BWColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: BWColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: BWColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: BWColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: BWColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: BWColors.textHint,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}

/// Full Material 3 ThemeData for the user web app.
ThemeData buildAppTheme() {
  final textTheme = BWTextTheme.textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: textTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BWColors.primary,
      primary: BWColors.primary,
      secondary: BWColors.secondary,
      tertiary: BWColors.accent,
      error: BWColors.error,
      surface: BWColors.surface,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: BWColors.background,
    cardTheme: CardThemeData(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      surfaceTintColor: Colors.transparent,
      color: BWColors.surface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BWColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
        borderSide: const BorderSide(color: BWColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
        borderSide: const BorderSide(color: BWColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
        borderSide: const BorderSide(color: BWColors.error),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BWSpacing.buttonRadius),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BWSpacing.buttonRadius),
        ),
        side: const BorderSide(color: BWColors.primary),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: BWColors.primary,
      foregroundColor: Colors.white,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(color: BWColors.divider, thickness: 1),
  );
}
