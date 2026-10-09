import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('bn')) {
    _load();
  }

  static const _key = 'app_locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key) ?? 'bn';
    state = Locale(v);
  }

  Future<void> setLocale(String code) async {
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
