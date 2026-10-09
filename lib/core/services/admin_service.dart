import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import 'video_service.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isAdmin() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final data = await _client
        .from(SupabaseConstants.profiles)
        .select('is_admin')
        .eq('id', uid)
        .maybeSingle();
    return data?['is_admin'] as bool? ?? false;
  }

  Future<List<StoryModel>> recentStories({int limit = 30}) async {
    final data = await _client
        .from(SupabaseConstants.stories)
        .select('''
          *,
          profiles:author_id (full_name, username, avatar_url)
        ''')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final p = map['profiles'];
      if (p is Map) {
        map['author_name'] = p['full_name'];
        map['author_username'] = p['username'];
        map['author_avatar'] = p['avatar_url'];
      }
      return StoryModel.fromJson(map);
    }).toList();
  }

  Future<void> unpublishStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).update({
      'is_published': false,
      'is_draft': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  Future<void> publishStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).update({
      'is_published': true,
      'is_draft': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  Future<void> deleteStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).delete().eq('id', storyId);
  }

  Future<List<UserModel>> recentUsers({int limit = 30}) async {
    final data = await _client
        .from(SupabaseConstants.profiles)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, int>> stats() async {
    final stories = await _client.from(SupabaseConstants.stories).select('id');
    final novels = await _client.from(SupabaseConstants.novels).select('id');
    final users = await _client.from(SupabaseConstants.profiles).select('id');
    final comments =
        await _client.from(SupabaseConstants.comments).select('id');
    return {
      'stories': (stories as List).length,
      'novels': (novels as List).length,
      'users': (users as List).length,
      'comments': (comments as List).length,
    };
  }

  // ---------- Video Feature Toggle Helpers ----------

  Future<bool> getVideoFeatureEnabled() async {
    return VideoService().isVideoFeatureEnabled();
  }

  Future<void> setVideoFeatureEnabled(bool enabled) async {
    await VideoService().setVideoFeatureEnabled(enabled);
  }
}
