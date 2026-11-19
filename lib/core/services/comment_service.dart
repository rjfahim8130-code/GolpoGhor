// lib/core/services/comment_service.dart
import 'package:flutter/foundation.dart';
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
    *, profiles:user_id (full_name, nickname, avatar_url)
  ''';

  Future<List<CommentModel>> _fetch({String? storyId, String? episodeId, String? novelId, String? videoId}) async {
    var query = _client.from(SupabaseConstants.comments).select(_selectWithProfile);
    if (storyId != null) query = query.eq('story_id', storyId);
    if (episodeId != null) query = query.eq('episode_id', episodeId);
    if (novelId != null) query = query.eq('novel_id', novelId);
    if (videoId != null) query = query.eq('video_id', videoId);

    final data = await query.order('created_at', ascending: true);
    return (data as List).map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<CommentModel> _insert({
    required String body,
    String? storyId, String? episodeId, String? novelId, String? videoId,
    String? parentId, String? replyToName, List<String> mentionedUserIds = const [], String? postOwnerId,
  }) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

    final text = body.trim();
    if (text.isEmpty) throw AppException('commentEmpty');
    if (text.length > AppConstants.commentMaxLength) throw AppException('commentTooLong');

    final data = await _client.from(SupabaseConstants.comments).insert({
      'user_id': uid,
      if (storyId != null) 'story_id': storyId,
      if (episodeId != null) 'episode_id': episodeId,
      if (novelId != null) 'novel_id': novelId,
      if (videoId != null) 'video_id': videoId,
      if (parentId != null) 'parent_id': parentId,
      if (replyToName != null && replyToName.trim().isNotEmpty) 'reply_to_name': replyToName.trim(),
      if (mentionedUserIds.isNotEmpty) 'mentioned_user_ids': mentionedUserIds,
      'body': text,
    }).select(_selectWithProfile).single();

    await _refreshCount(storyId: storyId, episodeId: episodeId, novelId: novelId, videoId: videoId);
    final created = CommentModel.fromJson(Map<String, dynamic>.from(data));

    // নোটিফিকেশন পাঠানো
    if (postOwnerId != null && postOwnerId.isNotEmpty && postOwnerId != uid) {
      final type = parentId != null ? 'reply' : 'comment';
      final targetType = _targetTypeFor(storyId: storyId, episodeId: episodeId, novelId: novelId, videoId: videoId);
      final targetId = storyId ?? episodeId ?? novelId ?? videoId;
      await _notif.create(targetUserId: postOwnerId, actorId: uid, type: type, targetType: targetType, targetId: targetId);
    }

    if (mentionedUserIds.isNotEmpty) {
      final targetType = _targetTypeFor(storyId: storyId, episodeId: episodeId, novelId: novelId, videoId: videoId);
      final targetId = storyId ?? episodeId ?? novelId ?? videoId ?? '';
      await _notif.createMentions(mentionedUserIds: mentionedUserIds, actorId: uid, commentId: created.id, targetType: targetType ?? 'story', targetId: targetId);
    }

    return created;
  }

  String? _targetTypeFor({String? storyId, String? episodeId, String? novelId, String? videoId}) {
    if (storyId != null) return 'story';
    if (episodeId != null) return 'episode';
    if (novelId != null) return 'novel';
    if (videoId != null) return 'video';
    return null;
  }

  // ... (getStoryComments, addStoryComment ইত্যাদি আগের মতোই, শুধু Exception গুলো AppException হবে)

  Future<void> _refreshCount({String? storyId, String? episodeId, String? novelId, String? videoId}) async {
    // (আগের কোডের মতোই থাকবে, তবে try-catch দিয়েwrap করা ভালো)
  }
}
