// lib/core/services/video_service.dart
// username বাদ, nickname যোগ

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/video_model.dart';

class VideoService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // username বাদ, nickname যোগ
  static const String _selectWithAuthor = '''
    *,
    profiles:author_id (
      full_name,
      nickname,
      avatar_url
    )
  ''';

  Map<String, dynamic> _mapAuthor(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final p = map['profiles'];
    if (p is Map) {
      map['author_name'] = p['full_name'];
      map['author_nickname'] = p['nickname'];
      map['author_avatar'] = p['avatar_url'];
    }
    return map;
  }

  // ---------- Feed ----------

  Future<List<VideoModel>> getFeed({int limit = 20, int offset = 0}) async {
    final data = await _client
        .from(SupabaseConstants.videoPosts)
        .select(_selectWithAuthor)
        .eq('is_published', true)
        .eq('is_draft', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((e) => VideoModel.fromJson(
              _mapAuthor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<VideoModel?> getById(String id) async {
    final data = await _client
        .from(SupabaseConstants.videoPosts)
        .select(_selectWithAuthor)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return VideoModel.fromJson(
      _mapAuthor(Map<String, dynamic>.from(data)),
    );
  }

  Future<List<VideoModel>> getByAuthor(
    String authorId, {
    int limit = 50,
  }) async {
    final data = await _client
        .from(SupabaseConstants.videoPosts)
        .select(_selectWithAuthor)
        .eq('author_id', authorId)
        .eq('is_published', true)
        .eq('is_draft', false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => VideoModel.fromJson(
              _mapAuthor(Map<String, dynamic>.from(e as Map)),
            ))
        .toList();
  }

  Future<VideoModel?> getNextPart(VideoModel current) async {
    if (current.seriesId == null || current.seriesId!.isEmpty) return null;
    final data = await _client
        .from(SupabaseConstants.videoPosts)
        .select(_selectWithAuthor)
        .eq('series_id', current.seriesId!)
        .eq('is_published', true)
        .eq('part_number', current.partNumber + 1)
        .maybeSingle();
    if (data == null) return null;
    return VideoModel.fromJson(
      _mapAuthor(Map<String, dynamic>.from(data)),
    );
  }

  Future<List<VideoModel>> getMyVideos() async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _client
        .from(SupabaseConstants.videoPosts)
        .select()
        .eq('author_id', uid)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => VideoModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------- Writes ----------

  Future<VideoModel> createVideo({
    required String videoUrl,
    required int durationSeconds,
    String title = '',
    String description = '',
    List<String> tags = const [],
    String? thumbnailUrl,
    String? seriesId,
    String? seriesTitle,
    int partNumber = 1,
    bool isDraft = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');

    final data = await _client
        .from(SupabaseConstants.videoPosts)
        .insert({
          'author_id': uid,
          'title': title.trim(),
          'description': description.trim(),
          'tags': tags,
          'video_url': videoUrl,
          'thumbnail_url': thumbnailUrl,
          'duration_seconds': durationSeconds,
          'series_id': seriesId,
          'series_title': seriesTitle,
          'part_number': partNumber,
          'is_published': !isDraft,
          'is_draft': isDraft,
        })
        .select()
        .single();

    return VideoModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<VideoModel> updateVideo({
    required String videoId,
    String? title,
    String? description,
    List<String>? tags,
    String? thumbnailUrl,
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
    if (tags != null) map['tags'] = tags;
    if (thumbnailUrl != null) map['thumbnail_url'] = thumbnailUrl;
    if (isDraft != null) {
      map['is_draft'] = isDraft;
      map['is_published'] = !isDraft;
    }
    if (isPublished != null) map['is_published'] = isPublished;

    final data = await _client
        .from(SupabaseConstants.videoPosts)
        .update(map)
        .eq('id', videoId)
        .eq('author_id', uid)
        .select()
        .single();

    return VideoModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteVideo(String videoId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    await _client
        .from(SupabaseConstants.videoPosts)
        .delete()
        .eq('id', videoId)
        .eq('author_id', uid);
  }

  // ---------- Save ----------

  Future<bool> isSaved(String videoId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _client
        .from(SupabaseConstants.videoSaves)
        .select('id')
        .eq('user_id', uid)
        .eq('video_id', videoId)
        .maybeSingle();
    return row != null;
  }

  Future<bool> toggleSave(String videoId) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    final existing = await isSaved(videoId);
    if (existing) {
      await _client
          .from(SupabaseConstants.videoSaves)
          .delete()
          .eq('user_id', uid)
          .eq('video_id', videoId);
      return false;
    }
    await _client.from(SupabaseConstants.videoSaves).insert({
      'user_id': uid,
      'video_id': videoId,
    });
    return true;
  }

  // ---------- View ----------

  Future<void> recordView(String videoId) async {
    try {
      await _client.rpc(
        SupabaseConstants.rpcRecordView,
        params: {'p_type': 'video', 'p_id': videoId},
      );
    } catch (_) {}
  }
}
