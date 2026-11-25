// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF159447);
  static const Color primaryDark = Color(0xFF0E6A32);
  static const Color primaryLight = Color(0xFF23AE5A);
  static const Color primaryAccent = Color(0xFF34C76E);

  static const Color accent = Color(0xFF159447);
  static const Color accentSoft = Color(0xFF23AE5A);

  // LIGHT THEME (#FFFFFF, #050505, #65676B, #E4E6EB)
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF050505);
  static const Color lightTextSecondary = Color(0xFF65676B);
  static const Color lightDivider = Color(0xFFE4E6EB);

  // DARK THEME (#18191A, #242526, #E4E6EB, #B0B3B8, #3E4042)
  static const Color darkBg = Color(0xFF18191A);
  static const Color darkSurface = Color(0xFF242526);
  static const Color darkCard = Color(0xFF242526);
  static const Color darkText = Color(0xFFE4E6EB);
  static const Color darkTextSecondary = Color(0xFFB0B3B8);
  static const Color darkDivider = Color(0xFF3E4042);

  // STATE
  static const Color success = Color(0xFF159447);
  static const Color warning = Color(0xFFF57C00);
  static const Color danger = Color(0xFFE41E3F);
  static const Color info = Color(0xFF1976D2);

  // REACTIONS
  static const Color like = Color(0xFF1976D2);
  static const Color love = Color(0xFFE41E3F);
  static const Color wow = Color(0xFFF57C00);
  static const Color sad = Color(0xFF5E35B1);
  static const Color fire = Color(0xFFE64A19);

  // READER
  static const Color sepiaBg = Color(0xFFF4ECD8);
  static const Color sepiaText = Color(0xFF3E2723);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryAccent],
  );
  static const LinearGradient forestDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );
}
