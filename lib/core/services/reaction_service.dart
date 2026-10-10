// lib/core/services/reaction_service.dart
// সংশোধিত: notification trigger সব reaction-এ

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import 'notification_service.dart';

class ReactionService {
  final SupabaseClient _client = Supabase.instance.client;
  final _notif = NotificationService();

  String? get _uid => _client.auth.currentUser?.id;

  // ---------------- Generic ----------------

  Future<String?> _getMine({
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    var q = _client
        .from(SupabaseConstants.reactions)
        .select('reaction_type')
        .eq('user_id', uid);
    if (storyId != null) q = q.eq('story_id', storyId);
    if (episodeId != null) q = q.eq('episode_id', episodeId);
    if (novelId != null) q = q.eq('novel_id', novelId);
    if (videoId != null) q = q.eq('video_id', videoId);

    final data = await q.maybeSingle();
    return data?['reaction_type'] as String?;
  }

  Future<Map<String, int>> _countAll({
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    var q = _client
        .from(SupabaseConstants.reactions)
        .select('reaction_type');
    if (storyId != null) q = q.eq('story_id', storyId);
    if (episodeId != null) q = q.eq('episode_id', episodeId);
    if (novelId != null) q = q.eq('novel_id', novelId);
    if (videoId != null) q = q.eq('video_id', videoId);

    final data = await q;
    final map = <String, int>{};
    for (final row in data as List) {
      final t = (row as Map)['reaction_type'] as String? ?? 'like';
      map[t] = (map[t] ?? 0) + 1;
    }
    return map;
  }

  /// রিটার্ন: নতুন reaction type, অথবা null যদি সরানো হয়
  Future<String?> _toggle({
    required String reactionType,
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
    String? ownerId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    var find = _client
        .from(SupabaseConstants.reactions)
        .select('id, reaction_type')
        .eq('user_id', uid);
    if (storyId != null) find = find.eq('story_id', storyId);
    if (episodeId != null) find = find.eq('episode_id', episodeId);
    if (novelId != null) find = find.eq('novel_id', novelId);
    if (videoId != null) find = find.eq('video_id', videoId);

    final existing = await find.maybeSingle();

    String? result;
    bool shouldNotify = false;

    if (existing != null) {
      final old = existing['reaction_type'] as String?;
      if (old == reactionType) {
        // সরানো
        var del = _client
            .from(SupabaseConstants.reactions)
            .delete()
            .eq('user_id', uid);
        if (storyId != null) del = del.eq('story_id', storyId);
        if (episodeId != null) del = del.eq('episode_id', episodeId);
        if (novelId != null) del = del.eq('novel_id', novelId);
        if (videoId != null) del = del.eq('video_id', videoId);
        await del;
        result = null;
      } else {
        // পরিবর্তন
        var upd = _client
            .from(SupabaseConstants.reactions)
            .update({'reaction_type': reactionType}).eq('user_id', uid);
        if (storyId != null) upd = upd.eq('story_id', storyId);
        if (episodeId != null) upd = upd.eq('episode_id', episodeId);
        if (novelId != null) upd = upd.eq('novel_id', novelId);
        if (videoId != null) upd = upd.eq('video_id', videoId);
        await upd;
        result = reactionType;
      }
    } else {
      // নতুন
      await _client.from(SupabaseConstants.reactions).insert({
        'user_id': uid,
        if (storyId != null) 'story_id': storyId,
        if (episodeId != null) 'episode_id': episodeId,
        if (novelId != null) 'novel_id': novelId,
        if (videoId != null) 'video_id': videoId,
        'reaction_type': reactionType,
      });
      result = reactionType;
      shouldNotify = true;
    }

    await _refreshCount(
      storyId: storyId,
      episodeId: episodeId,
      novelId: novelId,
      videoId: videoId,
    );

    // Notification — শুধু নতুন বা পরিবর্তনের সময়
    if (shouldNotify && ownerId != null && ownerId.isNotEmpty) {
      final targetType = _targetTypeFor(
        storyId: storyId,
        episodeId: episodeId,
        novelId: novelId,
        videoId: videoId,
      );
      final targetId = storyId ?? episodeId ?? novelId ?? videoId;
      await _notif.create(
        targetUserId: ownerId,
        actorId: uid,
        type: 'like',
        targetType: targetType,
        targetId: targetId,
      );
    }

    return result;
  }

  String? _targetTypeFor({
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) {
    if (storyId != null) return 'story';
    if (episodeId != null) return 'episode';
    if (novelId != null) return 'novel';
    if (videoId != null) return 'video';
    return null;
  }

  // ---------------- Story ----------------

  Future<String?> getMyStoryReaction(String storyId) =>
      _getMine(storyId: storyId);

  Future<Map<String, int>> countStoryReactions(String storyId) =>
      _countAll(storyId: storyId);

  Future<String?> toggleStoryReaction({
    required String storyId,
    required String reactionType,
    String? ownerId,
  }) =>
      _toggle(
        storyId: storyId,
        reactionType: reactionType,
        ownerId: ownerId,
      );

  // ---------------- Episode ----------------

  Future<String?> getMyEpisodeReaction(String episodeId) =>
      _getMine(episodeId: episodeId);

  Future<Map<String, int>> countEpisodeReactions(String episodeId) =>
      _countAll(episodeId: episodeId);

  Future<String?> toggleEpisodeReaction({
    required String episodeId,
    required String reactionType,
    String? ownerId,
  }) =>
      _toggle(
        episodeId: episodeId,
        reactionType: reactionType,
        ownerId: ownerId,
      );

  // ---------------- Novel ----------------

  Future<String?> getMyNovelReaction(String novelId) =>
      _getMine(novelId: novelId);

  Future<Map<String, int>> countNovelReactions(String novelId) =>
      _countAll(novelId: novelId);

  Future<String?> toggleNovelReaction({
    required String novelId,
    required String reactionType,
    String? ownerId,
  }) =>
      _toggle(
        novelId: novelId,
        reactionType: reactionType,
        ownerId: ownerId,
      );

  // ---------------- Video ----------------

  Future<String?> getMyVideoReaction(String videoId) =>
      _getMine(videoId: videoId);

  Future<int> countVideoReactions(String videoId) async {
    final all = await _client
        .from(SupabaseConstants.reactions)
        .select('id')
        .eq('video_id', videoId);
    return (all as List).length;
  }

  Future<String?> toggleVideoReaction({
    required String videoId,
    required String reactionType,
    String? ownerId,
  }) =>
      _toggle(
        videoId: videoId,
        reactionType: reactionType,
        ownerId: ownerId,
      );

  // ---------------- Count refresh ----------------

  Future<void> _refreshCount({
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    if (storyId != null) {
      final r = await _client
          .from(SupabaseConstants.reactions)
          .select('id')
          .eq('story_id', storyId);
      await _client
          .from(SupabaseConstants.stories)
          .update({'reaction_count': (r as List).length}).eq('id', storyId);
    }
    if (episodeId != null) {
      final r = await _client
          .from(SupabaseConstants.reactions)
          .select('id')
          .eq('episode_id', episodeId);
      await _client
          .from(SupabaseConstants.episodes)
          .update({'reaction_count': (r as List).length}).eq('id', episodeId);
    }
    if (novelId != null) {
      final r = await _client
          .from(SupabaseConstants.reactions)
          .select('id')
          .eq('novel_id', novelId);
      await _client
          .from(SupabaseConstants.novels)
          .update({'reaction_count': (r as List).length}).eq('id', novelId);
    }
    if (videoId != null) {
      final r = await _client
          .from(SupabaseConstants.reactions)
          .select('id')
          .eq('video_id', videoId);
      await _client
          .from(SupabaseConstants.videoPosts)
          .update({'reaction_count': (r as List).length}).eq('id', videoId);
    }
  }
}
