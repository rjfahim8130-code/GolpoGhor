// lib/core/services/follow_service.dart
// সংশোধিত: notification trigger + nickname select

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class FollowService {
  final SupabaseClient _client = Supabase.instance.client;
  final _notif = NotificationService();

  String? get _uid => _client.auth.currentUser?.id;

  Future<bool> isFollowing(String targetUserId) async {
    final uid = _uid;
    if (uid == null || uid == targetUserId) return false;
    final data = await _client
        .from(SupabaseConstants.follows)
        .select('follower_id')
        .eq('follower_id', uid)
        .eq('following_id', targetUserId)
        .maybeSingle();
    return data != null;
  }

  Future<bool> toggleFollow(String targetUserId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    if (uid == targetUserId) throw Exception('নিজেকে ফলো করা যায় না');

    final existing = await _client
        .from(SupabaseConstants.follows)
        .select('follower_id')
        .eq('follower_id', uid)
        .eq('following_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      // Unfollow
      await _client
          .from(SupabaseConstants.follows)
          .delete()
          .eq('follower_id', uid)
          .eq('following_id', targetUserId);
      await _adjustCounts(targetUserId, uid, delta: -1);
      return false;
    }

    // Follow
    await _client.from(SupabaseConstants.follows).insert({
      'follower_id': uid,
      'following_id': targetUserId,
    });
    await _adjustCounts(targetUserId, uid, delta: 1);

    // Notification
    await _notif.create(
      targetUserId: targetUserId,
      actorId: uid,
      type: 'follow',
      targetType: 'profile',
      targetId: uid,
    );

    return true;
  }

  Future<void> _adjustCounts(
    String followingId,
    String followerId, {
    required int delta,
  }) async {
    try {
      final target = await _client
          .from(SupabaseConstants.profiles)
          .select('follower_count')
          .eq('id', followingId)
          .maybeSingle();
      final me = await _client
          .from(SupabaseConstants.profiles)
          .select('following_count')
          .eq('id', followerId)
          .maybeSingle();

      final tCount =
          ((target?['follower_count'] as num?)?.toInt() ?? 0) + delta;
      final mCount =
          ((me?['following_count'] as num?)?.toInt() ?? 0) + delta;

      await _client.from(SupabaseConstants.profiles).update({
        'follower_count': tCount < 0 ? 0 : tCount,
      }).eq('id', followingId);

      await _client.from(SupabaseConstants.profiles).update({
        'following_count': mCount < 0 ? 0 : mCount,
      }).eq('id', followerId);
    } catch (_) {}
  }

  Future<List<UserModel>> getFollowers(String userId) async {
    final data = await _client
        .from(SupabaseConstants.follows)
        .select('''
          follower_id,
          profiles:follower_id (*)
        ''')
        .eq('following_id', userId)
        .order('created_at', ascending: false);

    final list = <UserModel>[];
    for (final row in data as List) {
      final p = (row as Map)['profiles'];
      if (p is Map) {
        list.add(UserModel.fromJson(Map<String, dynamic>.from(p)));
      }
    }
    return list;
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    final data = await _client
        .from(SupabaseConstants.follows)
        .select('''
          following_id,
          profiles:following_id (*)
        ''')
        .eq('follower_id', userId)
        .order('created_at', ascending: false);

    final list = <UserModel>[];
    for (final row in data as List) {
      final p = (row as Map)['profiles'];
      if (p is Map) {
        list.add(UserModel.fromJson(Map<String, dynamic>.from(p)));
      }
    }
    return list;
  }
}
