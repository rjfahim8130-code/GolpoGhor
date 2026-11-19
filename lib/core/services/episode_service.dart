// lib/core/services/episode_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/content_block_model.dart';
import '../models/episode_model.dart';
import 'auth_service.dart';

class EpisodeService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ... (Read মেথডগুলো আগের মতোই)

  Future<EpisodeModel> addEpisode({
    required String novelId,
    required String title,
    required List<ContentBlockModel> contentBlocks,
    int? chapterNumber,
  }) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

    final novel = await _client.from(SupabaseConstants.novels).select('author_id').eq('id', novelId).maybeSingle();
    if (novel == null || novel['author_id'] != uid) {
      throw AppException('noEpisodePermission');
    }

    int number = chapterNumber ?? 1;
    if (chapterNumber == null) {
      final existing = await _client.from(SupabaseConstants.episodes).select('chapter_number').eq('novel_id', novelId).order('chapter_number', ascending: false).limit(1);
      if ((existing as List).isNotEmpty) {
        number = ((existing.first as Map)['chapter_number'] as num).toInt() + 1;
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
    if (uid == null) throw AppException('notLoggedIn');

    final map = <String, dynamic>{ 'updated_at': DateTime.now().toIso8601String() };
    if (title != null) map['title'] = title.trim();
    if (contentBlocks != null) map['content_blocks'] = contentBlocks.map((e) => e.toJson()).toList();

    final data = await _client.from(SupabaseConstants.episodes).update(map).eq('id', episodeId).eq('author_id', uid).select().single();
    return EpisodeModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteEpisode(String episodeId) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');
    await _client.from(SupabaseConstants.episodes).delete().eq('id', episodeId).eq('author_id', uid);
  }

  Future<int> recordView(String episodeId) async {
    try {
      final result = await _client.rpc(SupabaseConstants.rpcRecordView, params: {'p_type': 'episode', 'p_id': episodeId});
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
