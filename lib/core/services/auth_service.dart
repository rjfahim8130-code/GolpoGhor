import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ---------- Auth ----------

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> setPassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> sendPasswordResetOtp(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final res = await _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
    if (res.user == null && res.session == null) {
      throw Exception('OTP সঠিক নয় বা মেয়াদ শেষ');
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ---------- Profile ----------

  Future<UserModel?> getMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    return getProfile(uid);
  }

  Future<UserModel?> getProfile(String userId) async {
    final data = await _client
        .from(SupabaseConstants.profiles)
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? profileSetupDone,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('লগইন নেই');

    final map = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) map['full_name'] = fullName.trim();
    if (username != null) {
      map['username'] = username.trim().toLowerCase().replaceAll(' ', '');
    }
    if (bio != null) map['bio'] = bio.trim();
    if (avatarUrl != null) map['avatar_url'] = avatarUrl;
    if (profileSetupDone != null) {
      map['profile_setup_done'] = profileSetupDone;
    }

    final data = await _client
        .from(SupabaseConstants.profiles)
        .update(map)
        .eq('id', uid)
        .select()
        .single();

    if (profileSetupDone == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_setup_done', true);
    }

    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> markProfileSetupDone() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client.from(SupabaseConstants.profiles).update({
      'profile_setup_done': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_setup_done', true);
  }

  Future<bool> needsProfileSetup() async {
    final p = await getMyProfile();
    if (p == null) return true;
    return !p.profileSetupDone;
  }
}
