// lib/core/providers/session_cache_provider.dart
// সংশোধিত: nickname যোগ, avatar cache, দ্রুত load

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// অফলাইনে বা startup-এ ইউজারের minimal তথ্য
final sessionCacheProvider =
    StateNotifierProvider<SessionCacheNotifier, UserModel?>((ref) {
  return SessionCacheNotifier();
});

class SessionCacheNotifier extends StateNotifier<UserModel?> {
  SessionCacheNotifier() : super(null);

  static const _keyId = 'cache_user_id';
  static const _keyName = 'cache_user_name';
  static const _keyNickname = 'cache_user_nickname';
  static const _keyAvatar = 'cache_user_avatar';
  static const _keyIsAdmin = 'cache_user_is_admin';
  static const _keySetupDone = 'cache_user_setup_done';

  /// app startup-এ কল হবে — preload
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_keyId);
      if (id == null) return;
      state = UserModel(
        id: id,
        fullName: prefs.getString(_keyName),
        nickname: prefs.getString(_keyNickname),
        avatarUrl: prefs.getString(_keyAvatar),
        isAdmin: prefs.getBool(_keyIsAdmin) ?? false,
        profileSetupDone: prefs.getBool(_keySetupDone) ?? false,
      );
    } catch (_) {}
  }

  Future<void> save(UserModel user) async {
    state = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyId, user.id);
      await prefs.setString(_keyName, user.fullName ?? '');
      await prefs.setString(_keyNickname, user.nickname ?? '');
      await prefs.setString(_keyAvatar, user.avatarUrl ?? '');
      await prefs.setBool(_keyIsAdmin, user.isAdmin);
      await prefs.setBool(_keySetupDone, user.profileSetupDone);
    } catch (_) {}
  }

  /// Avatar দ্রুত update — পূর্ণ profile load না করেই
  Future<void> updateAvatar(String? url) async {
    final cur = state;
    if (cur == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAvatar, url ?? '');
      state = cur.copyWith(avatarUrl: url);
    } catch (_) {}
  }

  Future<void> clear() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyId);
      await prefs.remove(_keyName);
      await prefs.remove(_keyNickname);
      await prefs.remove(_keyAvatar);
      await prefs.remove(_keyIsAdmin);
      await prefs.remove(_keySetupDone);
    } catch (_) {}
  }
}
