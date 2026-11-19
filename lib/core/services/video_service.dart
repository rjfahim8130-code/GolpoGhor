// lib/core/services/video_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/video_model.dart';
import 'auth_service.dart';

class VideoService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ... (Read মেথডগুলো আগের মতোই)

  Future<VideoModel> createVideo({
    required String videoUrl,
    required int durationSeconds,
    String title = '',
    String description = '',
    String? category,
    List<String> tags = const [],
    String? thumbnailUrl,
    String? seriesId,
    String? seriesTitle,
    int partNumber = 1,
    bool isDraft = false,
  }) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

    final row = <String, dynamic>{
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
    };

    if (category != null && category.isNotEmpty) {
      row['category'] = category;
    }

    final data = await _client.from(SupabaseConstants.videoPosts).insert(row).select().single();
    return VideoModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<VideoModel> updateVideo({
    required String videoId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
    bool? isDraft,
    bool? isPublished,
  }) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

    final map = <String, dynamic>{ 'updated_at': DateTime.now().toIso8601String() };
    if (title != null) map['title'] = title.trim();
    if (description != null) map['description'] = description.trim();
    if (category != null) map['category'] = category;
    if (tags != null) map['tags'] = tags;
    if (thumbnailUrl != null) map['thumbnail_url'] = thumbnailUrl;
    if (isDraft != null) {
      map['is_draft'] = isDraft;
      map['is_published'] = !isDraft;
    }
    if (isPublished != null) map['is_published'] = isPublished;

    final data = await _client.from(SupabaseConstants.videoPosts).update(map).eq('id', videoId).eq('author_id', uid).select().single();
    return VideoModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteVideo(String videoId) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');
    await _client.from(SupabaseConstants.videoPosts).delete().eq('id', videoId).eq('author_id', uid);
  }

  Future<bool> isSaved(String videoId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _client.from(SupabaseConstants.videoSaves).select('id').eq('user_id', uid).eq('video_id', videoId).maybeSingle();
    return row != null;
  }

  Future<bool> toggleSave(String videoId) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');
    final existing = await isSaved(videoId);
    if (existing) {
      await _client.from(SupabaseConstants.videoSaves).delete().eq('user_id', uid).eq('video_id', videoId);
      return false;
    }
    await _client.from(SupabaseConstants.videoSaves).insert({ 'user_id': uid, 'video_id': videoId });
    return true;
  }

  Future<void> recordView(String videoId) async {
    try {
      await _client.rpc(SupabaseConstants.rpcRecordView, params: {'p_type': 'video', 'p_id': videoId});
    } catch (e) {
      debugPrint('RECORD_VIEW_FAILED: $e');
    }
  }

  // ✅ নতুন যোগ করা হলো: Edge Function দিয়ে প্রিসাইনড URL জেনারেট করা (ভবিষ্যতের জন্য)
  Future<void> uploadVideoViaEdgeFunction(File videoFile, String objectKey) async {
    try {
      final res = await _client.functions.invoke('create-upload-url', body: {
        'objectKey': objectKey,
        'contentType': 'video/mp4',
      });

      final uploadUrl = res.data['uploadUrl'];
      if (uploadUrl == null) throw Exception('uploadUrl not found');

      final bytes = await videoFile.readAsBytes();
      final uploadRes = await http.put(Uri.parse(uploadUrl), headers: {'Content-Type': 'video/mp4'}, body: bytes);

      if (uploadRes.statusCode != 200) {
        throw Exception('Upload failed with status: ${uploadRes.statusCode}');
      }
    } catch (e) {
      debugPrint('EDGE_UPLOAD_FAILED: $e');
      throw AppException('uploadFailed');
    }
  }
}
