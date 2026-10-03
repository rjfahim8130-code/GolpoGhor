import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

class ReactionService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<String?> getMyStoryReaction(String storyId) async {
    final uid = _uid;
    if (uid == null) return null;
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('reaction_type')
        .eq('user_id', uid)
        .eq('story_id', storyId)
        .maybeSingle();
    return data?['reaction_type'] as String?;
  }

  Future<Map<String, int>> countStoryReactions(String storyId) async {
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('reaction_type')
        .eq('story_id', storyId);

    final map = <String, int>{};
    for (final row in data as List) {
      final t = (row as Map)['reaction_type'] as String? ?? 'like';
      map[t] = (map[t] ?? 0) + 1;
    }
    return map;
  }

  /// একই টাইপ আবার চাপলে রিমুভ; অন্য টাইপ হলে আপডেট
  Future<String?> toggleStoryReaction({
    required String storyId,
    required String reactionType,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final existing = await _client
        .from(SupabaseConstants.reactions)
        .select('id, reaction_type')
        .eq('user_id', uid)
        .eq('story_id', storyId)
        .maybeSingle();

    if (existing != null) {
      final old = existing['reaction_type'] as String?;
      if (old == reactionType) {
        await _client
            .from(SupabaseConstants.reactions)
            .delete()
            .eq('user_id', uid)
            .eq('story_id', storyId);
        await _refreshStoryReactionCount(storyId);
        return null;
      }
      await _client
          .from(SupabaseConstants.reactions)
          .update({'reaction_type': reactionType})
          .eq('user_id', uid)
          .eq('story_id', storyId);
      await _refreshStoryReactionCount(storyId);
      return reactionType;
    }

    await _client.from(SupabaseConstants.reactions).insert({
      'user_id': uid,
      'story_id': storyId,
      'reaction_type': reactionType,
    });
    await _refreshStoryReactionCount(storyId);
    return reactionType;
  }

  Future<void> _refreshStoryReactionCount(String storyId) async {
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('id')
        .eq('story_id', storyId);
    final count = (data as List).length;
    await _client
        .from(SupabaseConstants.stories)
        .update({'reaction_count': count}).eq('id', storyId);
  }
}
