// lib/core/services/episode_service.dart
// Service-এ context নেই — Exception-এ key string পাঠানো হবে

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/content_block_model.dart';
import '../models/episode_model.dart';

class EpisodeService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ---------- Reads ----------

  /// হোম ফিড — প্রকাশিত পর্ব, নতুন প্রকাশিত আগে
  Future<List<EpisodeModel>> getFeed({int limit = 15, int offset = 0}) async {
    final data = await _client
        .from(SupabaseConstants.episodes)
        .select('*, profiles:author_id (full_name, nickname, avatar_url), novels:novel_id (title)')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final p = map['profiles'];
      if (p is Map) {
        map['author_name'] = p['full_name'];
        map['author_nickname'] = p['nickname'];
        map['author_avatar'] = p['avatar_url'];
      }
      final n = map['novels'];
      if (n is Map) {
        map['novel_title'] = n['title'];
      }
      return EpisodeModel.fromJson(map);
    }).toList();
  }

  Future<List<EpisodeModel>> getByNovel(String novelId) async {
    final data = await _client
        .from(SupabaseConstants.episodes)
        .select()
        .eq('novel_id', novelId)
        .eq('is_published', true)
        .order('chapter_number', ascending: true);

    return (data as List)
        .map((e) => EpisodeModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<EpisodeModel?> getById(String id) async {
    final data = await _client
        .from(SupabaseConstants.episodes)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return EpisodeModel.fromJson(Map<String, dynamic>.from(data));
  }

  // ---------- Writes ----------

  Future<EpisodeModel> addEpisode({
    required String novelId,
    required String title,
    required List<ContentBlockModel> contentBlocks,
    int? chapterNumber,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('notLoggedIn');

    // novel owner check
    final novel = await _client
        .from(SupabaseConstants.novels)
        .select('author_id')
        .eq('id', novelId)
        .maybeSingle();
    if (novel == null || novel['author_id'] != uid) {
      throw Exception('noEpisodePermission');
    }

    // পর্ব নম্বর অটো
    int number = chapterNumber ?? 1;
    if (chapterNumber == null) {
      final existing = await _client
          .from(SupabaseConstants.episodes)
          .select('chapter_number')
          .eq('novel_id', novelId)
          .order('chapter_number', ascending: false)
          .limit(1);
      if ((existing as List).isNotEmpty) {
        number =
            ((existing.first as Map)['chapter_number'] as num).toInt() + 1;
      }
    }

    final data = await _client
        .from(SupabaseConstants.episodes)
        .insert({
          'novel_id': novelId,
          'author_id': uid,
          'chapter_number': number,
          'title': title.trim(),
          'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
          'is_published': true,
        })
        .select()
        .single();

    return EpisodeModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<EpisodeModel> updateEpisode({
    required String episodeId,
    String? title,
    List<ContentBlockModel>? contentBlocks,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('notLoggedIn');

    final map = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) map['title'] = title.trim();
    if (contentBlocks != null) {
      map['content_blocks'] = contentBlocks.map((e) => e.toJson()).toList();
    }

    final data = await _client
        .from(SupabaseConstants.episodes)
        .update(map)
        .eq('id', episodeId)
        .eq('author_id', uid)
        .select()
        .single();

    return EpisodeModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteEpisode(String episodeId) async {
    final uid = _uid;
    if (uid == null) throw Exception('notLoggedIn');
    await _client
        .from(SupabaseConstants.episodes)
        .delete()
        .eq('id', episodeId)
        .eq('author_id', uid);
  }

  Future<int> recordView(String episodeId) async {
    try {
      final result = await _client.rpc(
        SupabaseConstants.rpcRecordView,
        params: {'p_type': 'episode', 'p_id': episodeId},
      );
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
