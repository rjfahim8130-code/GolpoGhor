// lib/core/services/notification_service.dart
// সংশোধিত: সব event trigger সাপোর্ট, mention সহ

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  static const String _selectWithActor = '''
    *,
    actor:actor_id (
      full_name,
      nickname,
      avatar_url
    )
  ''';

  Map<String, dynamic> _mapActor(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final p = map['actor'];
    if (p is Map) {
      map['actor_name'] = p['full_name'];
      map['actor_nickname'] = p['nickname'];
      map['actor_avatar'] = p['avatar_url'];
    }
    return map;
  }

  // ---------------- Fetch ----------------

  Future<List<NotificationModel>> getMine({int limit = 50}) async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _client
        .from(SupabaseConstants.notifications)
        .select(_selectWithActor)
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => NotificationModel.fromJson(
              _mapActor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<int> unreadCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    final data = await _client
        .from(SupabaseConstants.notifications)
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);
    return (data as List).length;
  }

  // ---------------- Mark / Clear ----------------

  Future<void> markRead(String notificationId) async {
    await _client
        .from(SupabaseConstants.notifications)
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from(SupabaseConstants.notifications)
        .update({'is_read': true}).eq('user_id', uid);
  }

  Future<void> delete(String notificationId) async {
    await _client
        .from(SupabaseConstants.notifications)
        .delete()
        .eq('id', notificationId);
  }

  /// ২ দিনের পুরনো সব নোটিফিকেশন ডিলিট
  Future<void> clearOld() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final cutoff = DateTime.now()
          .subtract(
            const Duration(days: AppConstants.notificationRetentionDays),
          )
          .toUtc()
          .toIso8601String();

      await _client
          .from(SupabaseConstants.notifications)
          .delete()
          .eq('user_id', uid)
          .lt('created_at', cutoff);
    } catch (_) {}
  }

  /// ইউজার এক ক্লিকে সব ক্লিয়ার
  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from(SupabaseConstants.notifications)
        .delete()
        .eq('user_id', uid);
  }

  // ---------------- Create ----------------

  /// ইভেন্ট ঘটালে এটা কল হবে
  /// - Like → story/episode/novel/video owner
  /// - Comment → post owner
  /// - Reply → parent comment owner
  /// - Mention → যাকে mention করা হলো
  /// - Follow → target user
  Future<void> create({
    required String targetUserId,
    required String actorId,
    required String type,
    String? targetType,
    String? targetId,
    String? message,
  }) async {
    // নিজেকে নোটিফিকেশন দেব না
    if (targetUserId == actorId) return;
    if (targetUserId.isEmpty) return;

    try {
      await _client.from(SupabaseConstants.notifications).insert({
        'user_id': targetUserId,
        'actor_id': actorId,
        'type': type,
        if (targetType != null) 'target_type': targetType,
        if (targetId != null) 'target_id': targetId,
        if (message != null) 'message': message,
      });
    } catch (_) {}
  }

  /// একবারে একাধিক mention-এর জন্য
  /// comment-এ একাধিক @mention থাকলে প্রত্যেকের জন্য একটা notification
  Future<void> createMentions({
    required List<String> mentionedUserIds,
    required String actorId,
    required String commentId,
    required String targetType, // story | episode | video
    required String targetId, // post id
  }) async {
    for (final uid in mentionedUserIds) {
      if (uid == actorId) continue;
      await create(
        targetUserId: uid,
        actorId: actorId,
        type: 'mention',
        targetType: targetType,
        targetId: targetId,
        message: 'আপনাকে একটি মন্তব্যে মেনশন করেছেন',
      );
    }
  }
}
