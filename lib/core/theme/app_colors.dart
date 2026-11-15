// lib/core/theme/app_colors.dart
// গল্পঘর — Deep Forest Green থিম (গাঢ় সবুজ)

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════
  // PRIMARY — Deep Forest Green
  // ═══════════════════════════════════════════════
  static const Color primary       = Color(0xFF1B5E20); // Deep Forest
  static const Color primaryDark   = Color(0xFF0D3B12); // Darker Forest
  static const Color primaryLight  = Color(0xFF43A047); // Fresh Green
  static const Color primaryAccent = Color(0xFF66BB6A); // Soft Leaf

  // ═══════════════════════════════════════════════
  // SECONDARY — Warm Gold
  // ═══════════════════════════════════════════════
  static const Color accent     = Color(0xFFD4A017);
  static const Color accentSoft = Color(0xFFF4C430);

  // ═══════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════
  static const Color lightBg            = Color(0xFFF1F8F4);
  static const Color lightSurface       = Colors.white;
  static const Color lightCard          = Colors.white;
  static const Color lightText          = Color(0xFF102A14);
  static const Color lightTextSecondary = Color(0xFF5A6E5E);
  static const Color lightDivider       = Color(0xFFD8E6DA);

  // ═══════════════════════════════════════════════
  // DARK THEME — Deep Jungle
  // ═══════════════════════════════════════════════
  static const Color darkBg            = Color(0xFF0A1410);
  static const Color darkSurface       = Color(0xFF14201A);
  static const Color darkCard          = Color(0xFF1A2A22);
  static const Color darkText          = Color(0xFFF0F5F1);
  static const Color darkTextSecondary = Color(0xFF9FB3A4);
  static const Color darkDivider       = Color(0xFF243830);

  // ═══════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color danger  = Color(0xFFC62828);
  static const Color info    = Color(0xFF1976D2);

  // ═══════════════════════════════════════════════
  // REACTIONS
  // ═══════════════════════════════════════════════
  static const Color like = Color(0xFF1976D2);
  static const Color love = Color(0xFFC62828);
  static const Color wow  = Color(0xFFF57C00);
  static const Color sad  = Color(0xFF5E35B1);
  static const Color fire = Color(0xFFE64A19);

  // ═══════════════════════════════════════════════
  // READER — Sepia
  // ═══════════════════════════════════════════════
  static const Color sepiaBg   = Color(0xFFF4ECD8);
  static const Color sepiaText = Color(0xFF3E2723);

  // ═══════════════════════════════════════════════
  // Gradient helpers
  // ═══════════════════════════════════════════════
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentSoft],
  );

  static const LinearGradient forestDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );
}
