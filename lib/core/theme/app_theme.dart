// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

  static const Color _lightBg = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE4E6EB);
  static const Color _lightText = Color(0xFF000000);
  static const Color _lightTextSecondary = Color(0xFF65676B);

  static const Color _darkBg = Color(0xFF18191A);
  static const Color _darkSurface = Color(0xFF242526);
  static const Color _darkCard = Color(0xFF242526);
  static const Color _darkBorder = Color(0xFF3E4042);
  static const Color _darkText = Color(0xFFFFFFFF);
  static const Color _darkTextSecondary = Color(0xFFB0B3B8);

  static TextTheme _bn(TextTheme base, Color color) {
    return GoogleFonts.notoSansBengaliTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _brandGreen,
        brightness: Brightness.light,
        primary: _brandGreen,
        error: _dangerColor,
        surface: _lightSurface,
      ),
      scaffoldBackgroundColor: _lightBg,
    );

    return base.copyWith(
      textTheme: _bn(base.textTheme, _lightText),
      primaryTextTheme: _bn(base.primaryTextTheme, _lightText),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _lightBg,
        foregroundColor: _lightText,
        titleTextStyle: GoogleFonts.notoSansBengali(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _lightText,
        ),
      ),
      dividerColor: _lightBorder,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansBengali(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandGreen,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: _brandGreen, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _brandGreen),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brandGreen, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _lightText,
        contentTextStyle: GoogleFonts.notoSansBengali(
          color: Colors.white,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _brandGreen,
        unselectedLabelColor: _lightTextSecondary,
        indicatorColor: _brandGreen,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _brandGreen,
        brightness: Brightness.dark,
        primary: _brandGreen,
        error: _dangerColor,
        surface: _darkSurface,
      ),
      scaffoldBackgroundColor: _darkBg,
    );

    return base.copyWith(
      textTheme: _bn(base.textTheme, _darkText),
      primaryTextTheme: _bn(base.primaryTextTheme, _darkText),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _darkBg,
        foregroundColor: _darkText,
        titleTextStyle: GoogleFonts.notoSansBengali(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _darkText,
        ),
      ),
      dividerColor: _darkBorder,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.notoSansBengali(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _brandGreen,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: _brandGreen, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _brandGreen),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _brandGreen, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _darkCard,
        contentTextStyle: GoogleFonts.notoSansBengali(
          color: _darkText,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _brandGreen,
        unselectedLabelColor: _darkTextSecondary,
        indicatorColor: _brandGreen,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }
}
