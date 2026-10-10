// lib/core/services/comment_service.dart
// সংশোধিত: mention support, nickname join, notification trigger

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import '../models/comment_model.dart';
import 'notification_service.dart';

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;
  final _notif = NotificationService();

  String? get _uid => _client.auth.currentUser?.id;

  // username বাদ, nickname যোগ
  static const String _selectWithProfile = '''
    *,
    profiles:user_id (
      full_name,
      nickname,
      avatar_url
    )
  ''';

  // ---------------- Generic helpers ----------------

  Future<List<CommentModel>> _fetch({
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    var query = _client
        .from(SupabaseConstants.comments)
        .select(_selectWithProfile);

    if (storyId != null) query = query.eq('story_id', storyId);
    if (episodeId != null) query = query.eq('episode_id', episodeId);
    if (novelId != null) query = query.eq('novel_id', novelId);
    if (videoId != null) query = query.eq('video_id', videoId);

    final data = await query.order('created_at', ascending: true);

    return (data as List)
        .map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// কমেন্ট যোগ
  /// - notification তৈরি হবে post owner-এর জন্য (comment/reply)
  /// - mentioned_user_ids-এ যাদের নাম আছে তাদের জন্য mention notification
  Future<CommentModel> _insert({
    required String body,
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
    String? parentId,
    String? replyToName,
    List<String> mentionedUserIds = const [],
    String? postOwnerId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final text = body.trim();
    if (text.isEmpty) throw Exception('মন্তব্য খালি');
    if (text.length > AppConstants.commentMaxLength) {
      throw Exception('মন্তব্য অনেক বড়');
    }

    final data = await _client
        .from(SupabaseConstants.comments)
        .insert({
          'user_id': uid,
          if (storyId != null) 'story_id': storyId,
          if (episodeId != null) 'episode_id': episodeId,
          if (novelId != null) 'novel_id': novelId,
          if (videoId != null) 'video_id': videoId,
          if (parentId != null) 'parent_id': parentId,
          if (replyToName != null && replyToName.trim().isNotEmpty)
            'reply_to_name': replyToName.trim(),
          if (mentionedUserIds.isNotEmpty)
            'mentioned_user_ids': mentionedUserIds,
          'body': text,
        })
        .select(_selectWithProfile)
        .single();

    await _refreshCount(
      storyId: storyId,
      episodeId: episodeId,
      novelId: novelId,
      videoId: videoId,
    );

    final created = CommentModel.fromJson(Map<String, dynamic>.from(data));

    // ---------- Notifications ----------
    // ১) Post owner-কে
    if (postOwnerId != null && postOwnerId.isNotEmpty) {
      final type = parentId != null ? 'reply' : 'comment';
      final targetType = _targetTypeFor(
        storyId: storyId,
        episodeId: episodeId,
        novelId: novelId,
        videoId: videoId,
      );
      final targetId = storyId ?? episodeId ?? novelId ?? videoId;

      await _notif.create(
        targetUserId: postOwnerId,
        actorId: uid,
        type: type,
        targetType: targetType,
        targetId: targetId,
      );
    }

    // ২) Mentioned users-দের জন্য
    if (mentionedUserIds.isNotEmpty) {
      final targetType = _targetTypeFor(
        storyId: storyId,
        episodeId: episodeId,
        novelId: novelId,
        videoId: videoId,
      );
      final targetId = storyId ?? episodeId ?? novelId ?? videoId ?? '';
      await _notif.createMentions(
        mentionedUserIds: mentionedUserIds,
        actorId: uid,
        commentId: created.id,
        targetType: targetType ?? 'story',
        targetId: targetId,
      );
    }

    return created;
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

  Future<List<CommentModel>> getStoryComments(String storyId) =>
      _fetch(storyId: storyId);

  Future<CommentModel> addStoryComment({
    required String storyId,
    required String body,
    String? parentId,
    String? replyToName,
    List<String> mentionedUserIds = const [],
    String? postOwnerId,
  }) =>
      _insert(
        storyId: storyId,
        body: body,
        parentId: parentId,
        replyToName: replyToName,
        mentionedUserIds: mentionedUserIds,
        postOwnerId: postOwnerId,
      );

  // ---------------- Episode ----------------

  Future<List<CommentModel>> getEpisodeComments(String episodeId) =>
      _fetch(episodeId: episodeId);

  Future<CommentModel> addEpisodeComment({
    required String episodeId,
    required String body,
    String? parentId,
    String? replyToName,
    List<String> mentionedUserIds = const [],
    String? postOwnerId,
  }) =>
      _insert(
        episodeId: episodeId,
        body: body,
        parentId: parentId,
        replyToName: replyToName,
        mentionedUserIds: mentionedUserIds,
        postOwnerId: postOwnerId,
      );

  // ---------------- Video ----------------

  Future<List<CommentModel>> getVideoComments(String videoId) =>
      _fetch(videoId: videoId);

  Future<CommentModel> addVideoComment({
    required String videoId,
    required String body,
    String? parentId,
    String? replyToName,
    List<String> mentionedUserIds = const [],
    String? postOwnerId,
  }) =>
      _insert(
        videoId: videoId,
        body: body,
        parentId: parentId,
        replyToName: replyToName,
        mentionedUserIds: mentionedUserIds,
        postOwnerId: postOwnerId,
      );

  // ---------------- Delete ----------------

  Future<void> deleteComment(
    String commentId, {
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    await _client
        .from(SupabaseConstants.comments)
        .delete()
        .eq('id', commentId)
        .eq('user_id', uid);

    await _refreshCount(
      storyId: storyId,
      episodeId: episodeId,
      novelId: novelId,
      videoId: videoId,
    );
  }
