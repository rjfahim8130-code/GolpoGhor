// lib/core/services/story_service.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import '../models/content_block_model.dart';
import '../models/story_model.dart';
import 'auth_service.dart'; // AppException

class StoryService {
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

  // ... (getFeed, getTrending, getPopular, getByCategory, getByCategories, getByAuthor, getById, getMyStories আগের মতোই থাকবে)
  // নিচে শুধু Write অংশটুকু দেওয়া হলো, পুরো কোডটা আপনার কাছে থাকা উচিত, শুধু Write অংশে AppException বসিয়ে নিন।

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
    if (uid == null) throw AppException('notLoggedIn');

    // কনটেন্ট সাইজ লিমিট চেক (যেমন ৫০০ কিলোবাইট)
    final blocksJson = contentBlocks.map((e) => e.toJson()).toList();
    final sizeInBytes = utf8.encode(jsonEncode(blocksJson)).length;
    if (sizeInBytes > 500 * 1024) {
      throw AppException('contentTooLarge');
    }

    final data = await _client
        .from(SupabaseConstants.stories)
        .insert({
          'author_id': uid,
          'title': title.trim(),
          'description': description?.trim() ?? '',
          'category': category,
          'tags': tags ?? [],
          'cover_url': coverUrl,
          'content_blocks': blocksJson,
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
    if (uid == null) throw AppException('notLoggedIn');

    final map = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) map['title'] = title.trim();
    if (description != null) map['description'] = description.trim();
    if (category != null) map['category'] = category;
    if (tags != null) map['tags'] = tags;
    if (coverUrl != null) map['cover_url'] = coverUrl;
    if (contentBlocks != null) {
      final blocksJson = contentBlocks.map((e) => e.toJson()).toList();
      final sizeInBytes = utf8.encode(jsonEncode(blocksJson)).length;
      if (sizeInBytes > 500 * 1024) throw AppException('contentTooLarge');
      map['content_blocks'] = blocksJson;
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
    if (uid == null) throw AppException('notLoggedIn');
    await _client.from(SupabaseConstants.stories).delete().eq('id', storyId).eq('author_id', uid);
  }

  Future<int> recordView(String storyId) async {
    try {
      final result = await _client.rpc(SupabaseConstants.rpcRecordView, params: {'p_type': 'story', 'p_id': storyId});
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
