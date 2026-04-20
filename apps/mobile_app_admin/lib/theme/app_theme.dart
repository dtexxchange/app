import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Admin App Primary: Green
  static const Color primary = Color(0xFF00FF9D);
  static const Color primaryDark = Color(0xFF00CC7E);

  // Neutral Colors - Light Mode
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textDimLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Neutral Colors - Dark Mode
  static const Color bgDark = Color(0xFF0A0B0D);
  static const Color cardDark = Color(0xFF15171C);
  static const Color textMainDark = Colors.white;
  static const Color textDimDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0x0DFFFFFF);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bgLight,
      cardColor: cardLight,
      dividerColor: borderLight,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: textMainLight, displayColor: textMainLight),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: cardLight,
        onSurface: textMainLight,
        onSurfaceVariant: textDimLight,
        outline: borderLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: textMainLight,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgLight,
        indicatorColor: primary.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: bgDark,
      cardColor: cardDark,
      dividerColor: borderDark,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textMainDark, displayColor: textMainDark),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: cardDark,
        onSurface: textMainDark,
        onSurfaceVariant: textDimDark,
        outline: borderDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textMainDark,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgDark,
        indicatorColor: primary.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textDimDark,
          ),
        ),
      ),
    );
  }
}
