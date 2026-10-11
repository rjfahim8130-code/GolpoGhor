// lib/core/services/bookmark_service.dart
// username বাদ, nickname যোগ

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/novel_model.dart';
import '../models/story_model.dart';

class BookmarkService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════
  // Helper: Saved list-এর জন্য select statement
  // ═══════════════════════════════════════════════════════════
  static const String _savedStorySelect = '''
    story_id,
    stories:story_id (
      *,
      profiles:author_id (
        full_name,
        nickname,
        avatar_url
      )
    )
  ''';

  static const String _savedNovelSelect = '''
    novel_id,
    novels:novel_id (
      *,
      profiles:author_id (
        full_name,
        nickname,
        avatar_url
      )
    )
  ''';

  // ═══════════════════════════════════════════════════════════
  // Helper: JSON-এ author info যোগ করে
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> _mapWithAuthor(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final p = map['profiles'];
    if (p is Map) {
      map['author_name'] = p['full_name'];
      map['author_nickname'] = p['nickname'];
      map['author_avatar'] = p['avatar_url'];
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════════
  // Story Bookmark
  // ═══════════════════════════════════════════════════════════

  /// Story bookmark করা আছে কি?
  Future<bool> isStoryBookmarked(String storyId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final data = await _client
          .from(SupabaseConstants.bookmarks)
          .select('id')
          .eq('user_id', uid)
          .eq('story_id', storyId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  /// Story bookmark toggle
  /// Returns: নতুন state (true = bookmarked, false = removed)
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
      // Remove
      await _client
          .from(SupabaseConstants.bookmarks)
          .delete()
          .eq('user_id', uid)
          .eq('story_id', storyId);
      return false;
    }

    // Add
    await _client.from(SupabaseConstants.bookmarks).insert({
      'user_id': uid,
      'story_id': storyId,
    });
    return true;
  }

  // ═══════════════════════════════════════════════════════════
  // Novel Bookmark
  // ═══════════════════════════════════════════════════════════

  /// Novel bookmark করা আছে কি?
  Future<bool> isNovelBookmarked(String novelId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final data = await _client
          .from(SupabaseConstants.bookmarks)
          .select('id')
          .eq('user_id', uid)
          .eq('novel_id', novelId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  /// Novel bookmark toggle
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

  // ═══════════════════════════════════════════════════════════
  // Saved List (সম্পূর্ণ তথ্য সহ)
  // ═══════════════════════════════════════════════════════════

  /// ইউজারের সব saved story
  /// প্রতিটি story-তে author info সহ আসে (nickname সহ)
  Future<List<StoryModel>> getSavedStories() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final data = await _client
          .from(SupabaseConstants.bookmarks)
          .select(_savedStorySelect)
          .eq('user_id', uid)
          .not('story_id', 'is', null)
          .order('created_at', ascending: false);

      final list = <StoryModel>[];
      for (final row in data as List) {
        final s = (row as Map)['stories'];
        if (s is Map) {
          final map = _mapWithAuthor(Map<String, dynamic>.from(s));
          try {
            list.add(StoryModel.fromJson(map));
          } catch (_) {
            // একটা row fail হলেও বাকিগুলো লোড হবে
          }
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// ইউজারের সব saved novel
  Future<List<NovelModel>> getSavedNovels() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final data = await _client
          .from(SupabaseConstants.bookmarks)
          .select(_savedNovelSelect)
          .eq('user_id', uid)
          .not('novel_id', 'is', null)
          .order('created_at', ascending: false);

      final list = <NovelModel>[];
      for (final row in data as List) {
        final n = (row as Map)['novels'];
        if (n is Map) {
          final map = _mapWithAuthor(Map<String, dynamic>.from(n));
          try {
            list.add(NovelModel.fromJson(map));
          } catch (_) {}
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Statistics
  // ═══════════════════════════════════════════════════════════

  /// মোট bookmark কতটি (story + novel)
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

  /// শুধু story bookmark count
  Future<int> getStoryBookmarkCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final data = await _client
          .from(SupabaseConstants.bookmarks)
          .select('id')
          .eq('user_id', uid)
          .not('story_id', 'is', null);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// শুধু novel bookmark count
  Future<int> getNovelBookmarkCount() async {
    final uid = _uid;
    if (uid == null) return 0;
    try {
      final data = await _client
          .from(SupabaseConstants.bookmarks)
          .select('id')
          .eq('user_id', uid)
          .not('novel_id', 'is', null);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }
}
