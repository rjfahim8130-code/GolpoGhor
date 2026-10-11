// lib/core/services/bookmark_service.dart
// username বাদ, nickname যোগ

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/novel_model.dart';
import '../models/story_model.dart';

class BookmarkService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ---------- Story ----------

  Future<bool> isStoryBookmarked(String storyId) async {
    final uid = _uid;
    if (uid == null) return false;
    final data = await _client
        .from(SupabaseConstants.bookmarks)
        .select('id')
        .eq('user_id', uid)
        .eq('story_id', storyId)
        .maybeSingle();
    return data != null;
  }

  Future<bool> toggleStoryBookmark(String storyId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final existing = await _client
        .from(SupabaseConstants.bookmarks)
        .select('id')
        .eq('user_id', uid)
        .eq('story_id', storyId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from(SupabaseConstants.bookmarks)
          .delete()
          .eq('user_id', uid)
          .eq('story_id', storyId);
      return false;
    }

    await _client.from(SupabaseConstants.bookmarks).insert({
      'user_id': uid,
      'story_id': storyId,
    });
    return true;
  }

  // ---------- Novel ----------

  Future<bool> isNovelBookmarked(String novelId) async {
    final uid = _uid;
    if (uid == null) return false;
    final data = await _client
        .from(SupabaseConstants.bookmarks)
        .select('id')
        .eq('user_id', uid)
        .eq('novel_id', novelId)
        .maybeSingle();
    return data != null;
  }

  Future<bool> toggleNovelBookmark(String novelId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final existing = await _client
        .from(SupabaseConstants.bookmarks)
        .select('id')
        .eq('user_id', uid)
        .eq('novel_id', novelId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from(SupabaseConstants.bookmarks)
          .delete()
          .eq('user_id', uid)
          .eq('novel_id', novelId);
      return false;
    }

    await _client.from(SupabaseConstants.bookmarks).insert({
      'user_id': uid,
      'novel_id': novelId,
    });
    return true;
  }

  // ---------- Saved list ----------

  Future<List<StoryModel>> getSavedStories() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _client
        .from(SupabaseConstants.bookmarks)
        .select('''
          story_id,
          stories:story_id (
            *,
            profiles:author_id (
              full_name,
              nickname,
              avatar_url
            )
          )
        ''')
        .eq('user_id', uid)
        .not('story_id', 'is', null)
        .order('created_at', ascending: false);

    final list = <StoryModel>[];
    for (final row in data as List) {
      final s = (row as Map)['stories'];
      if (s is Map) {
        final map = Map<String, dynamic>.from(s);
        final profiles = map['profiles'];
        if (profiles is Map) {
          map['author_name'] = profiles['full_name'];
          map['author_nickname'] = profiles['nickname'];
          map['author_avatar'] = profiles['avatar_url'];
        }
        try {
          list.add(StoryModel.fromJson(map));
        } catch (_) {}
      }
    }
    return list;
  }

  Future<List<NovelModel>> getSavedNovels() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _client
        .from(SupabaseConstants.bookmarks)
        .select('''
          novel_id,
          novels:novel_id (
            *,
            profiles:author_id (
              full_name,
              nickname,
              avatar_url
            )
          )
        ''')
        .eq('user_id', uid)
        .not('novel_id', 'is', null)
        .order('created_at', ascending: false);

    final list = <NovelModel>[];
    for (final row in data as List) {
      final n = (row as Map)['novels'];
      if (n is Map) {
        final map = Map<String, dynamic>.from(n);
        final profiles = map['profiles'];
        if (profiles is Map) {
          map['author_name'] = profiles['full_name'];
          map['author_nickname'] = profiles['nickname'];
          map['author_avatar'] = profiles['avatar_url'];
        }
        try {
          list.add(NovelModel.fromJson(map));
        } catch (_) {}
      }
    }
    return list;
  }

  Future<int> getTotalBookmarkCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final data = await _client
          .from(SupabaseConstants.bookmarks)
          .select('id')
          .eq('user_id', uid);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }
}
