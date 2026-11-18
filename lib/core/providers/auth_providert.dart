// lib/core/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// বর্তমানে লগইন করা ইউজারের AuthState স্ট্রিম
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// বর্তমানে লগইন করা ইউজার (null = লগইন নেই)
final currentUserProvider = Provider<User?>((ref) {
  // authStateProvider পরিবর্তন হলে এটি রি-বিল্ড হবে
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});
