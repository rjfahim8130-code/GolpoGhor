// lib/core/services/reaction_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class ReactionService {
  final SupabaseClient _client = Supabase.instance.client;
  final _notif = NotificationService();
  String? get _uid => _client.auth.currentUser?.id;

  // ... (_getMine, _countAll আগের মতোই)

  Future<String?> _toggle({
    required String reactionType,
    String? storyId, String? episodeId, String? novelId, String? videoId,
    String? ownerId,
  }) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

    // (আগের লজিকের মতোই থাকবে: delete/update/insert)

    // নোটিফিকেশন পাঠানো
    if (ownerId != null && ownerId.isNotEmpty && ownerId != uid) {
      final targetType = _targetTypeFor(storyId: storyId, episodeId: episodeId, novelId: novelId, videoId: videoId);
      final targetId = storyId ?? episodeId ?? novelId ?? videoId;
      await _notif.create(targetUserId: ownerId, actorId: uid, type: 'like', targetType: targetType, targetId: targetId);
    }

    return result;
  }

  // ... (_targetTypeFor, toggleStoryReaction, _refreshCount আগের মতোই থাকবে, শুধু AppException বসবে)
}
