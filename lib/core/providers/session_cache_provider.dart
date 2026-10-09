import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// অফলাইনে ঢুকলে ইউজারের minimal তথ্য এখান থেকে দেখাবে
/// (নাম, avatar, id)
final sessionCacheProvider =
    StateNotifierProvider<SessionCacheNotifier, UserModel?>((ref) {
  return SessionCacheNotifier();
});

class SessionCacheNotifier extends StateNotifier<UserModel?> {
  SessionCacheNotifier() : super(null) {
    _load();
  }

  static const _keyId = 'cache_user_id';
  static const _keyName = 'cache_user_name';
  static const _keyUsername = 'cache_user_username';
  static const _keyAvatar = 'cache_user_avatar';
  static const _keyIsAdmin = 'cache_user_is_admin';
  static const _keySetupDone = 'cache_user_setup_done';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyId);
    if (id == null) return;
    state = UserModel(
      id: id,
      fullName: prefs.getString(_keyName),
      username: prefs.getString(_keyUsername),
      avatarUrl: prefs.getString(_keyAvatar),
      isAdmin: prefs.getBool(_keyIsAdmin) ?? false,
      profileSetupDone: prefs.getBool(_keySetupDone) ?? false,
    );
  }

  Future<void> save(UserModel user) async {
    state = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyId, user.id);
    await prefs.setString(_keyName, user.fullName ?? '');
    await prefs.setString(_keyUsername, user.username ?? '');
    await prefs.setString(_keyAvatar, user.avatarUrl ?? '');
    await prefs.setBool(_keyIsAdmin, user.isAdmin);
    await prefs.setBool(_keySetupDone, user.profileSetupDone);
  }

  Future<void> updateAvatar(String? url) async {
    final cur = state;
    if (cur == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatar, url ?? '');
    state = cur.copyWith(avatarUrl: url);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyAvatar);
    await prefs.remove(_keyIsAdmin);
    await prefs.remove(_keySetupDone);
  }
}
