import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

class ReactionService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ───────── গল্প ─────────

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
    await _client
        .from(SupabaseConstants.stories)
        .update({'reaction_count': (data as List).length}).eq('id', storyId);
  }

  // ───────── পর্ব ─────────

  Future<String?> getMyEpisodeReaction(String episodeId) async {
    final uid = _uid;
    if (uid == null) return null;
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('reaction_type')
        .eq('user_id', uid)
        .eq('episode_id', episodeId)
        .maybeSingle();
    return data?['reaction_type'] as String?;
  }

  Future<Map<String, int>> countEpisodeReactions(String episodeId) async {
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('reaction_type')
        .eq('episode_id', episodeId);

    final map = <String, int>{};
    for (final row in data as List) {
      final t = (row as Map)['reaction_type'] as String? ?? 'like';
      map[t] = (map[t] ?? 0) + 1;
    }
    return map;
  }

  Future<String?> toggleEpisodeReaction({
    required String episodeId,
    required String reactionType,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final existing = await _client
        .from(SupabaseConstants.reactions)
        .select('id, reaction_type')
        .eq('user_id', uid)
        .eq('episode_id', episodeId)
        .maybeSingle();

    if (existing != null) {
      final old = existing['reaction_type'] as String?;
      if (old == reactionType) {
        await _client
            .from(SupabaseConstants.reactions)
            .delete()
            .eq('user_id', uid)
            .eq('episode_id', episodeId);
        await _refreshEpisodeReactionCount(episodeId);
        return null;
      }
      await _client
          .from(SupabaseConstants.reactions)
          .update({'reaction_type': reactionType})
          .eq('user_id', uid)
          .eq('episode_id', episodeId);
      await _refreshEpisodeReactionCount(episodeId);
      return reactionType;
    }

    await _client.from(SupabaseConstants.reactions).insert({
      'user_id': uid,
      'episode_id': episodeId,
      'reaction_type': reactionType,
    });
    await _refreshEpisodeReactionCount(episodeId);
    return reactionType;
  }

  Future<void> _refreshEpisodeReactionCount(String episodeId) async {
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('id')
        .eq('episode_id', episodeId);
    final count = (data as List).length;
    await _client
        .from(SupabaseConstants.episodes)
        .update({'reaction_count': count}).eq('id', episodeId);
  }

  // ───────── ভিডিও ─────────

  Future<String?> getMyVideoReaction(String videoId) async {
    final uid = _uid;
    if (uid == null) return null;
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('reaction_type')
        .eq('user_id', uid)
        .eq('video_id', videoId)
        .maybeSingle();
    return data?['reaction_type'] as String?;
  }

  Future<int> countVideoReactions(String videoId) async {
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('id')
        .eq('video_id', videoId);
    return (data as List).length;
  }

  Future<String?> toggleVideoReaction({
    required String videoId,
    required String reactionType,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final existing = await _client
        .from(SupabaseConstants.reactions)
        .select('id, reaction_type')
        .eq('user_id', uid)
        .eq('video_id', videoId)
        .maybeSingle();

    if (existing != null) {
      final old = existing['reaction_type'] as String?;
      if (old == reactionType) {
        await _client
            .from(SupabaseConstants.reactions)
            .delete()
            .eq('user_id', uid)
            .eq('video_id', videoId);
        await _refreshVideoReactionCount(videoId);
        return null;
      }
      await _client
          .from(SupabaseConstants.reactions)
          .update({'reaction_type': reactionType})
          .eq('user_id', uid)
          .eq('video_id', videoId);
      await _refreshVideoReactionCount(videoId);
      return reactionType;
    }

    await _client.from(SupabaseConstants.reactions).insert({
      'user_id': uid,
      'video_id': videoId,
      'reaction_type': reactionType,
    });
    await _refreshVideoReactionCount(videoId);
    return reactionType;
  }

  Future<void> _refreshVideoReactionCount(String videoId) async {
    final data = await _client
        .from(SupabaseConstants.reactions)
        .select('id')
        .eq('video_id', videoId);
    final count = (data as List).length;
    await _client
        .from(SupabaseConstants.videoPosts)
        .update({'reaction_count': count}).eq('id', videoId);
  }
}
