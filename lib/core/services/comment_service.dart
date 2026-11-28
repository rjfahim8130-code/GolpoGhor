// lib/core/services/comment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import '../models/comment_model.dart';
import 'notification_service.dart';
import 'auth_service.dart'; // AppException

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;
  final _notif = NotificationService();

  String? get _uid => _client.auth.currentUser?.id;

  static const String _selectWithProfile = '''
    *,
    profiles:user_id (
      full_name,
      nickname,
      avatar_url
    )
  ''';

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
    if (uid == null) throw AppException('notLoggedIn');

    final text = body.trim();
    if (text.isEmpty) throw AppException('commentEmpty');
    if (text.length > AppConstants.commentMaxLength) {
      throw AppException('commentTooLong');
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

  Future<List<CommentModel>> getVideoComments(String videoId) =>
      _fetch(videoId: videoId);

  /// Fetch replies (child comments) for a parent comment.
  Future<List<CommentModel>> getReplies(String parentId) async {
    final data = await _client
        .from(SupabaseConstants.comments)
        .select(_selectWithProfile)
        .eq('parent_id', parentId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

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

  Future<void> deleteComment(
    String commentId, {
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

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

  Future<void> deleteCommentAsOwner(String commentId) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');
    await _client.from(SupabaseConstants.comments).delete().eq('id', commentId);
  }

  Future<bool> isCommentLiked(String commentId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _client
        .from(SupabaseConstants.commentLikes)
        .select('user_id')
        .eq('user_id', uid)
        .eq('comment_id', commentId)
        .maybeSingle();
    return row != null;
  }

  Future<bool> toggleCommentLike(String commentId) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

    final existing = await _client
        .from(SupabaseConstants.commentLikes)
        .select('user_id')
        .eq('user_id', uid)
        .eq('comment_id', commentId)
        .maybeSingle();

    bool liked;
    if (existing != null) {
      await _client
          .from(SupabaseConstants.commentLikes)
          .delete()
          .eq('user_id', uid)
          .eq('comment_id', commentId);
      liked = false;
    } else {
      await _client.from(SupabaseConstants.commentLikes).insert({
        'user_id': uid,
        'comment_id': commentId,
      });
      liked = true;
    }

    final likes = await _client
        .from(SupabaseConstants.commentLikes)
        .select('user_id')
        .eq('comment_id', commentId);
    await _client
        .from(SupabaseConstants.comments)
        .update({'like_count': (likes as List).length}).eq('id', commentId);

    return liked;
  }

  Future<void> _refreshCount({
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    if (storyId != null) {
      final all = await _client.from(SupabaseConstants.comments).select('id').eq('story_id', storyId);
      await _client.from(SupabaseConstants.stories).update({'comment_count': (all as List).length}).eq('id', storyId);
    }
    if (episodeId != null) {
      final all = await _client.from(SupabaseConstants.comments).select('id').eq('episode_id', episodeId);
      await _client.from(SupabaseConstants.episodes).update({'comment_count': (all as List).length}).eq('id', episodeId);
    }
    if (novelId != null) {
      final all = await _client.from(SupabaseConstants.comments).select('id').eq('novel_id', novelId);
      await _client.from(SupabaseConstants.novels).update({'comment_count': (all as List).length}).eq('id', novelId);
    }
    if (videoId != null) {
      final all = await _client.from(SupabaseConstants.comments).select('id').eq('video_id', videoId);
      await _client.from(SupabaseConstants.videoPosts).update({'comment_count': (all as List).length}).eq('id', videoId);
    }
  }
}
