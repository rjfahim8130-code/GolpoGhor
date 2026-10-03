import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<List<CommentModel>> getStoryComments(String storyId) async {
    final data = await _client
        .from(SupabaseConstants.comments)
        .select('''
          *,
          profiles:user_id (
            full_name,
            username,
            avatar_url
          )
        ''')
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
        .select('''
          *,
          profiles:user_id (
            full_name,
            username,
            avatar_url
          )
        ''')
        .single();

    await _refreshStoryCommentCount(storyId);
    return CommentModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteComment(String commentId, {String? storyId}) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    await _client
        .from(SupabaseConstants.comments)
        .delete()
        .eq('id', commentId)
        .eq('user_id', uid);
    if (storyId != null) await _refreshStoryCommentCount(storyId);
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
    final data = await _client
        .from(SupabaseConstants.comments)
        .select('id')
        .eq('story_id', storyId)
        .isFilter('parent_id', null);
    // সব কমেন্ট (রিপ্লাইসহ) কাউন্ট
    final all = await _client
        .from(SupabaseConstants.comments)
        .select('id')
        .eq('story_id', storyId);
    await _client
        .from(SupabaseConstants.stories)
        .update({'comment_count': (all as List).length}).eq('id', storyId);
  }
}
