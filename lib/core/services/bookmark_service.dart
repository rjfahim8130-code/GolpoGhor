import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class BookmarkService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

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
}
