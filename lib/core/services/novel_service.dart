// lib/core/services/novel_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import '../models/novel_model.dart';
import 'auth_service.dart';

class NovelService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  static const String _selectWithAuthor = '''
    *,
    profiles:author_id (full_name, nickname, avatar_url)
  ''';

  Map<String, dynamic> _mapWithAuthor(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final profiles = map['profiles'];
    if (profiles is Map) {
      map['author_name'] = profiles['full_name'];
      map['author_nickname'] = profiles['nickname'];
      map['author_avatar'] = profiles['avatar_url'];
    }
    return map;
  }

  // ... (Read মেথডগুলো আগের মতোই)

  Future<NovelModel> createNovel({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? coverUrl,
    bool isDraft = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

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
    if (uid == null) throw AppException('notLoggedIn');

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
    if (uid == null) throw AppException('notLoggedIn');

    await _client.from(SupabaseConstants.episodes).delete().eq('novel_id', novelId).eq('author_id', uid);
    await _client.from(SupabaseConstants.novels).delete().eq('id', novelId).eq('author_id', uid);
  }

  Future<int> recordView(String novelId) async {
    try {
      final result = await _client.rpc(SupabaseConstants.rpcRecordView, params: {'p_type': 'novel', 'p_id': novelId});
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
