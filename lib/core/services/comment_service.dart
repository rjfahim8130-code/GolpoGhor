import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  static const _selectWithProfile = '''
    *,
    profiles:user_id (
      full_name,
      username,
      avatar_url
    )
  ''';

  // ───────── গল্প ─────────

  Future<List<CommentModel>> getStoryComments(String storyId) async {
    final data = await _client
        .from(SupabaseConstants.comments)
        .select(_selectWithProfile)
        .eq('story_id', storyId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CommentModel> addStoryComment({
    required String storyId,
    required String body,
    String? parentId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    final text = body.trim();
    if (text.isEmpty) throw Exception('কমেন্ট খালি');

    final data = await _client
        .from(SupabaseConstants.comments)
        .insert({
          'user_id': uid,
          'story_id': storyId,
          'body': text,
          if (parentId != null) 'parent_id': parentId,
        })
        .select(_selectWithProfile)
        .single();

    await _refreshStoryCommentCount(storyId);
    return CommentModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ───────── পর্ব ─────────

  Future<List<CommentModel>> getEpisodeComments(String episodeId) async {
    final data = await _client
        .from(SupabaseConstants.comments)
        .select(_selectWithProfile)
        .eq('episode_id', episodeId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CommentModel> addEpisodeComment({
    required String episodeId,
    required String body,
    String? parentId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    final text = body.trim();
    if (text.isEmpty) throw Exception('কমেন্ট খালি');

    final data = await _client
        .from(SupabaseConstants.comments)
        .insert({
          'user_id': uid,
          'episode_id': episodeId,
          'body': text,
          if (parentId != null) 'parent_id': parentId,
        })
        .select(_selectWithProfile)
        .single();

    await _refreshEpisodeCommentCount(episodeId);
    return CommentModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ───────── সাধারণ ─────────

  Future<void> deleteComment(
    String commentId, {
    String? storyId,
    String? episodeId,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    await _client
        .from(SupabaseConstants.comments)
        .delete()
        .eq('id', commentId)
        .eq('user_id', uid);
    if (storyId != null) await _refreshStoryCommentCount(storyId);
    if (episodeId != null) await _refreshEpisodeCommentCount(episodeId);
  }

  Future<void> toggleCommentLike(String commentId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final existing = await _client
        .from(SupabaseConstants.commentLikes)
        .select('user_id')
        .eq('user_id', uid)
        .eq('comment_id', commentId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from(SupabaseConstants.commentLikes)
          .delete()
          .eq('user_id', uid)
          .eq('comment_id', commentId);
    } else {
      await _client.from(SupabaseConstants.commentLikes).insert({
        'user_id': uid,
        'comment_id': commentId,
      });
    }

    final likes = await _client
        .from(SupabaseConstants.commentLikes)
        .select('user_id')
        .eq('comment_id', commentId);
    await _client
        .from(SupabaseConstants.comments)
        .update({'like_count': (likes as List).length}).eq('id', commentId);
  }

  Future<void> _refreshStoryCommentCount(String storyId) async {
    final all = await _client
        .from(SupabaseConstants.comments)
        .select('id')
        .eq('story_id', storyId);
    await _client
        .from(SupabaseConstants.stories)
        .update({'comment_count': (all as List).length}).eq('id', storyId);
  }

  Future<void> _refreshEpisodeCommentCount(String episodeId) async {
    final all = await _client
        .from(SupabaseConstants.comments)
        .select('id')
        .eq('episode_id', episodeId);
    await _client
        .from(SupabaseConstants.episodes)
        .update({'comment_count': (all as List).length}).eq('id', episodeId);
  }
}
