import 'package:shared_preferences/shared_preferences.dart';

class LastRouteStorage {
  static const _key = 'last_route';

  static Future<void> save(String location) async {
    // auth/splash সেভ করবেন না
    const skip = ['/splash', '/welcome', '/login', '/register',
      '/onboarding', '/forgot-password', '/profile-setup'];
    if (skip.any((s) => location == s || location.startsWith('$s/'))) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, location);
  }

  static Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
