// lib/core/providers/locale_provider.dart
// সংশোধিত: default = system (ফোনের ভাষা), manual change সাপোর্ট

import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// null = system locale (ফোনের ভাষা)
/// non-null = user-selected locale
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null);

  static const _key = 'app_locale';
  static const _systemTag = 'system';

  /// main.dart থেকে কল হবে
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      if (v == null || v.isEmpty || v == _systemTag) {
        state = null;
      } else {
        state = Locale(v);
      }
    } catch (_) {
      state = null;
    }
  }

  /// code = 'bn' / 'en' / 'system' / null
  Future<void> setLocale(String? code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code == null ||
          code.isEmpty ||
          code == _systemTag) {
        state = null;
        await prefs.setString(_key, _systemTag);
      } else {
        state = Locale(code);
        await prefs.setString(_key, code);
      }
    } catch (_) {
      state = null;
    }
  }

  bool get isSystem => state == null;
  String get currentCode => state?.languageCode ?? _systemTag;
}
