import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/content_block_model.dart';
import '../models/episode_model.dart';
import '../models/novel_model.dart';

class NovelService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  Map<String, dynamic> _mapWithAuthor(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final profiles = map['profiles'];
    if (profiles is Map) {
      map['author_name'] = profiles['full_name'];
      map['author_username'] = profiles['username'];
      map['author_avatar'] = profiles['avatar_url'];
    }
    return map;
  }

  Future<List<NovelModel>> getFeed({int limit = 10, int offset = 0}) async {
    final data = await _client
        .from(SupabaseConstants.novels)
        .select('''
          *,
          profiles:author_id (
            full_name,
            username,
            avatar_url
          )
        ''')
        .eq('is_published', true)
        .eq('is_draft', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((e) => NovelModel.fromJson(
              _mapWithAuthor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<List<NovelModel>> getMyNovels() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _client
        .from(SupabaseConstants.novels)
        .select()
        .eq('author_id', uid)
        .order('updated_at', ascending: false);

    return (data as List)
        .map((e) => NovelModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<NovelModel?> getById(String id) async {
    final data = await _client
        .from(SupabaseConstants.novels)
        .select('''
          *,
          profiles:author_id (
            full_name,
            username,
            avatar_url
          )
        ''')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return NovelModel.fromJson(
      _mapWithAuthor(Map<String, dynamic>.from(data)),
    );
  }

  Future<List<EpisodeModel>> getEpisodes(String novelId) async {
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

  Future<EpisodeModel?> getEpisodeById(String id) async {
    final data = await _client
        .from(SupabaseConstants.episodes)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return EpisodeModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<NovelModel> createNovel({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? coverUrl,
    bool isDraft = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final data = await _client
        .from(SupabaseConstants.novels)
        .insert({
          'author_id': uid,
          'title': title.trim(),
          'description': description?.trim() ?? '',
          'category': category,
          'tags': tags ?? [],
          'cover_url': coverUrl,
          'is_published': !isDraft,
          'is_draft': isDraft,
        })
        .select()
        .single();

    return NovelModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<EpisodeModel> addEpisode({
    required String novelId,
    required String title,
    required List<ContentBlockModel> contentBlocks,
    String? coverUrl,
    int? chapterNumber,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    // শুধু নিজের উপন্যাসে পর্ব যোগ করার অনুমতি চেক
    final novel = await _client
        .from(SupabaseConstants.novels)
        .select('author_id')
        .eq('id', novelId)
        .maybeSingle();
    if (novel == null || novel['author_id'] != uid) {
      throw Exception('এই উপন্যাসে পর্ব যোগ করার অনুমতি নেই');
    }

    int number = chapterNumber ?? 1;
    if (chapterNumber == null) {
      final existing = await _client
          .from(SupabaseConstants.episodes)
          .select('chapter_number')
          .eq('novel_id', novelId)
          .order('chapter_number', ascending: false)
          .limit(1);
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
          'cover_url': coverUrl,
          'is_published': true,
        })
        .select()
        .single();

    return EpisodeModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<int> recordView(String type, String id) async {
    try {
      final result = await _client.rpc(
        'record_view',
        params: {'p_type': type, 'p_id': id},
      );
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
