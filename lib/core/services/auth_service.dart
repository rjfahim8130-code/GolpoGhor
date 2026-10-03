import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// ইমেইল + পাসওয়ার্ড রেজিস্টার (ভেরিফিকেশন OFF ধরে)
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

  /// Google Sign-In → Supabase
  Future<AuthResponse?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('Google ID Token পাওয়া যায়নি');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Google ইউজার পাসওয়ার্ড সেট / পরিবর্তন
  Future<void> setPassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _client.auth.signOut();
  }

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

    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> markProfileSetupDone() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _client.from(SupabaseConstants.profiles).update({
      'profile_setup_done': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }

  Future<bool> needsProfileSetup() async {
    final p = await getMyProfile();
    if (p == null) return true;
    return !p.profileSetupDone;
  }
}
