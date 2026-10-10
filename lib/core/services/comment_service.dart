import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  static const String _selectWithProfile = '''
    *,
    profiles:user_id (
      full_name,
      username,
      avatar_url
    )
  ''';

  // ---------- Generic helpers ----------

  Future<List<CommentModel>> _fetch({
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    var query = _client.from(SupabaseConstants.comments).select(_selectWithProfile);

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

    return CommentModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ---------- Story ----------

  Future<List<CommentModel>> getStoryComments(String storyId) =>
      _fetch(storyId: storyId);

  Future<CommentModel> addStoryComment({
    required String storyId,
    required String body,
    String? parentId,
    String? replyToName,
  }) =>
      _insert(
        storyId: storyId,
        body: body,
        parentId: parentId,
        replyToName: replyToName,
      );

  // ---------- Episode ----------

  Future<List<CommentModel>> getEpisodeComments(String episodeId) =>
      _fetch(episodeId: episodeId);

  Future<CommentModel> addEpisodeComment({
    required String episodeId,
    required String body,
    String? parentId,
    String? replyToName,
  }) =>
      _insert(
        episodeId: episodeId,
        body: body,
        parentId: parentId,
        replyToName: replyToName,
      );

  // ---------- Novel ----------

  Future<List<CommentModel>> getNovelComments(String novelId) =>
      _fetch(novelId: novelId);

  Future<CommentModel> addNovelComment({
    required String novelId,
    required String body,
    String? parentId,
    String? replyToName,
  }) =>
      _insert(
        novelId: novelId,
        body: body,
        parentId: parentId,
        replyToName: replyToName,
      );

  // ---------- Video ----------

  Future<List<CommentModel>> getVideoComments(String videoId) =>
      _fetch(videoId: videoId);

  Future<CommentModel> addVideoComment({
    required String videoId,
    required String body,
    String? parentId,
    String? replyToName,
  }) =>
      _insert(
        videoId: videoId,
        body: body,
        parentId: parentId,
        replyToName: replyToName,
      );

  // ---------- Delete ----------

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

  /// পোস্ট মালিক অন্যদের কমেন্ট ডিলিট করতে পারবে
  Future<void> deleteCommentAsOwner(String commentId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    await _client.from(SupabaseConstants.comments).delete().eq('id', commentId);
  }

  // ---------- Like ----------

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
    if (uid == null) throw Exception('লগইন নেই');

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

    // like count refresh
    final likes = await _client
        .from(SupabaseConstants.commentLikes)
        .select('user_id')
        .eq('comment_id', commentId);
    await _client
        .from(SupabaseConstants.comments)
        .update({'like_count': (likes as List).length}).eq('id', commentId);

    return liked;
  }

  // ---------- Count refresh ----------

  Future<void> _refreshCount({
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
  }) async {
    if (storyId != null) {
      final all = await _client
          .from(SupabaseConstants.comments)
          .select('id')
          .eq('story_id', storyId);
      await _client
          .from(SupabaseConstants.stories)
          .update({'comment_count': (all as List).length}).eq('id', storyId);
    }
    if (episodeId != null) {
      final all = await _client
          .from(SupabaseConstants.comments)
          .select('id')
          .eq('episode_id', episodeId);
      await _client
          .from(SupabaseConstants.episodes)
          .update({'comment_count': (all as List).length}).eq('id', episodeId);
    }
    if (novelId != null) {
      final all = await _client
          .from(SupabaseConstants.comments)
          .select('id')
          .eq('novel_id', novelId);
      await _client
          .from(SupabaseConstants.novels)
          .update({'comment_count': (all as List).length}).eq('id', novelId);
    }
    if (videoId != null) {
      final all = await _client
          .from(SupabaseConstants.comments)
          .select('id')
          .eq('video_id', videoId);
      await _client
          .from(SupabaseConstants.videoPosts)
          .update({'comment_count': (all as List).length}).eq('id', videoId);
    }
  }
}
