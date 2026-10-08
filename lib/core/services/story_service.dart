import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import '../models/content_block_model.dart';
import '../models/story_model.dart';

class StoryService {
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

  Future<List<StoryModel>> getFeed({
    int limit = AppConstants.feedPageSize,
    int offset = 0,
  }) async {
    final data = await _client
        .from(SupabaseConstants.stories)
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
        .map((e) => StoryModel.fromJson(
              _mapWithAuthor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<List<StoryModel>> getTrending({int limit = 20}) async {
    final data = await _client
        .from(SupabaseConstants.stories)
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
        .order('view_count', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => StoryModel.fromJson(
              _mapWithAuthor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<List<StoryModel>> getPopular({int limit = 40}) async {
    final data = await _client
        .from(SupabaseConstants.stories)
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
        .order('reaction_count', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => StoryModel.fromJson(
              _mapWithAuthor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<List<StoryModel>> getByCategory(String category, {int limit = 30}) async {
    final data = await _client
        .from(SupabaseConstants.stories)
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
        .eq('category', category)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => StoryModel.fromJson(
              _mapWithAuthor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<StoryModel?> getById(String id) async {
    final data = await _client
        .from(SupabaseConstants.stories)
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
    return StoryModel.fromJson(
      _mapWithAuthor(Map<String, dynamic>.from(data)),
    );
  }

  Future<StoryModel?> getByCode(String code) async {
    final data = await _client
        .from(SupabaseConstants.stories)
        .select('''
          *,
          profiles:author_id (
            full_name,
            username,
            avatar_url
          )
        ''')
        .eq('public_code', code.trim().toUpperCase())
        .maybeSingle();

    if (data == null) {
      final data2 = await _client
          .from(SupabaseConstants.stories)
          .select('''
            *,
            profiles:author_id (
              full_name,
              username,
              avatar_url
            )
          ''')
          .ilike('public_code', code.trim())
          .maybeSingle();
      if (data2 == null) return null;
      return StoryModel.fromJson(
        _mapWithAuthor(Map<String, dynamic>.from(data2)),
      );
    }
    return StoryModel.fromJson(
      _mapWithAuthor(Map<String, dynamic>.from(data)),
    );
  }

  Future<List<StoryModel>> getMyStories({bool draftsOnly = false}) async {
    final uid = _uid;
    if (uid == null) return [];

    if (draftsOnly) {
      final data = await _client
          .from(SupabaseConstants.stories)
          .select()
          .eq('author_id', uid)
          .eq('is_draft', true)
          .order('updated_at', ascending: false);
      return (data as List)
          .map((e) => StoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final data = await _client
        .from(SupabaseConstants.stories)
        .select()
        .eq('author_id', uid)
        .order('updated_at', ascending: false);

    return (data as List)
        .map((e) => StoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<StoryModel> createStory({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? coverUrl,
    required List<ContentBlockModel> contentBlocks,
    bool isDraft = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final data = await _client
        .from(SupabaseConstants.stories)
        .insert({
          'author_id': uid,
          'title': title.trim(),
          'description': description?.trim() ?? '',
          'category': category,
          'tags': tags ?? [],
          'cover_url': coverUrl,
          'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
          'is_published': !isDraft,
          'is_draft': isDraft,
        })
        .select()
        .single();

    return StoryModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<StoryModel> updateStory({
    required String storyId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? coverUrl,
    List<ContentBlockModel>? contentBlocks,
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
    if (contentBlocks != null) {
      map['content_blocks'] = contentBlocks.map((e) => e.toJson()).toList();
    }
    if (isDraft != null) {
      map['is_draft'] = isDraft;
      map['is_published'] = !isDraft;
    }
    if (isPublished != null) map['is_published'] = isPublished;

    final data = await _client
        .from(SupabaseConstants.stories)
        .update(map)
        .eq('id', storyId)
        .eq('author_id', uid)
        .select()
        .single();

    return StoryModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteStory(String storyId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    await _client
        .from(SupabaseConstants.stories)
        .delete()
        .eq('id', storyId)
        .eq('author_id', uid);
  }

  Future<int> recordView(String storyId) async {
    try {
      final result = await _client.rpc(
        'record_view',
        params: {'p_type': 'story', 'p_id': storyId},
      );
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
