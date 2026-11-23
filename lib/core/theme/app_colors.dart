import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // আপনার দেওয়া নতুন সবুজ (#159447)
  static const Color primary       = Color(0xFF159447);
  static const Color primaryDark   = Color(0xFF0D6B32);
  static const Color primaryLight  = Color(0xFF34B36A);

  static const Color accent     = Color(0xFFD4A017);
  
  // ⬛ LIGHT THEME (ফেসবুকের মতো একদম সাদা)
  static const Color lightBg            = Color(0xFFFFFFFF);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightCard          = Color(0xFFFFFFFF);
  static const Color lightText          = Color(0xFF1C1E21); // গাঢ় কালো টেক্সট
  static const Color lightTextSecondary = Color(0xFF65676B); // ধূসর টেক্সট
  static const Color lightDivider       = Color(0xFFCED0D4); // হালকা বর্ডার

  // ⬛ DARK THEME (ফেসবুকের মতো গাঢ় কালো)
  static const Color darkBg            = Color(0xFF18191A); // মেইন ব্যাকগ্রাউন্ড
  static const Color darkSurface       = Color(0xFF242526); // প্যানেল/সারফেস
  static const Color darkCard          = Color(0xFF242526); // কার্ড
  static const Color darkText          = Color(0xFFE4E6EB); // উজ্জ্বল সাদা টেক্সট
  static const Color darkTextSecondary = Color(0xFFB0B3B8); // ধূসর টেক্সট
  static const Color darkDivider       = Color(0xFF3E4042); // ডার্ক বর্ডার

  // STATE
  static const Color success = Color(0xFF31A24C);
  static const Color warning = Color(0xFFF7B928);
  static const Color danger  = Color(0xFFFA3E3E);
  static const Color info    = Color(0xFF1877F2);

  // REACTIONS
  static const Color like = Color(0xFF1877F2);
  static const Color love = Color(0xFFF3425F);
  static const Color wow  = Color(0xFFF7B928);
  static const Color sad  = Color(0xFF5E35B1);
  static const Color fire = Color(0xFFE64A19);

  // READER (আগের ৩টি মোড অপরিবর্তিত)
  static const Color sepiaBg   = Color(0xFFF4ECD8);
  static const Color sepiaText = Color(0xFF3E2723);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}
