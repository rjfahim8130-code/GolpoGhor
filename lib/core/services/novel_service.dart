import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import '../models/novel_model.dart';

class NovelService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  static const String _selectWithAuthor = '''
    *,
    profiles:author_id (
      full_name,
      username,
      avatar_url
    )
  ''';

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

  // ---------- Reads ----------

  Future<List<NovelModel>> getFeed({
    int limit = AppConstants.feedPageSize,
    int offset = 0,
  }) async {
    final data = await _client
        .from(SupabaseConstants.novels)
        .select(_selectWithAuthor)
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

  Future<List<NovelModel>> getByAuthor(String authorId, {int limit = 50}) async {
    final data = await _client
        .from(SupabaseConstants.novels)
        .select(_selectWithAuthor)
        .eq('author_id', authorId)
        .eq('is_published', true)
        .eq('is_draft', false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => NovelModel.fromJson(
              _mapWithAuthor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<NovelModel?> getById(String id) async {
    final data = await _client
        .from(SupabaseConstants.novels)
        .select(_selectWithAuthor)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return NovelModel.fromJson(
      _mapWithAuthor(Map<String, dynamic>.from(data)),
    );
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

  // ---------- Writes ----------

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

  Future<NovelModel> updateNovel({
    required String novelId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? coverUrl,
    bool? isDraft,
    bool? isPublished,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final map = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) map['title'] = title.trim();
    if (description != null) map['description'] = description.trim();
    if (category != null) map['category'] = category;
    if (tags != null) map['tags'] = tags;
    if (coverUrl != null) map['cover_url'] = coverUrl;
    if (isDraft != null) {
      map['is_draft'] = isDraft;
      map['is_published'] = !isDraft;
    }
    if (isPublished != null) map['is_published'] = isPublished;

    final data = await _client
        .from(SupabaseConstants.novels)
        .update(map)
        .eq('id', novelId)
        .eq('author_id', uid)
        .select()
        .single();

    return NovelModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteNovel(String novelId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    // আগে সব পর্ব মুছি
    await _client
        .from(SupabaseConstants.episodes)
        .delete()
        .eq('novel_id', novelId)
        .eq('author_id', uid);

    // তারপর উপন্যাস
    await _client
        .from(SupabaseConstants.novels)
        .delete()
        .eq('id', novelId)
        .eq('author_id', uid);
  }

  Future<int> recordView(String novelId) async {
    try {
      final result = await _client.rpc(
        SupabaseConstants.rpcRecordView,
        params: {'p_type': 'novel', 'p_id': novelId},
      );
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
