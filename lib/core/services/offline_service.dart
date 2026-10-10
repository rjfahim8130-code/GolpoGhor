import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_block_model.dart';
import '../models/story_model.dart';

/// অফলাইনে ডাউনলোড করা কনটেন্ট — শুধু অ্যাপে পড়া যাবে
class OfflineItem {
  final String id; // story id বা ep_<episodeId>
  final String title;
  final String? subtitle; // উপন্যাসের নাম (episode-এর জন্য)
  final String? authorName;
  final String? publicCode;
  final String? coverUrl;
  final String? description;
  final String? category;
  final DateTime savedAt;
  final List<ContentBlockModel> contentBlocks;
  final String kind; // story | episode

  OfflineItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.authorName,
    this.publicCode,
    this.coverUrl,
    this.description,
    this.category,
    required this.savedAt,
    required this.contentBlocks,
    this.kind = 'story',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'author_name': authorName,
        'public_code': publicCode,
        'cover_url': coverUrl,
        'description': description,
        'category': category,
        'saved_at': savedAt.toIso8601String(),
        'kind': kind,
        'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
      };

  factory OfflineItem.fromJson(Map<String, dynamic> json) {
    final blocks = <ContentBlockModel>[];
    final raw = json['content_blocks'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          blocks.add(ContentBlockModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return OfflineItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      authorName: json['author_name'] as String?,
      publicCode: json['public_code'] as String?,
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      savedAt: DateTime.tryParse(json['saved_at']?.toString() ?? '') ??
          DateTime.now(),
      contentBlocks: blocks,
      kind: json['kind'] as String? ?? 'story',
    );
  }

  StoryModel toStoryModel() {
    return StoryModel(
      id: id,
      authorId: '',
      title: title,
      description: description ?? '',
      category: category,
      coverUrl: coverUrl,
      contentBlocks: contentBlocks,
      publicCode: publicCode,
      isPublished: true,
      createdAt: savedAt,
      authorName: authorName,
      viewCount: 0,
    );
  }
}

class OfflineService {
  static const _indexKey = 'offline_item_ids';

  Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/offline_content');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> _file(String id) async {
    final d = await _dir();
    return File('${d.path}/$id.json');
  }

  Future<List<String>> _ids() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_indexKey) ?? [];
  }

  Future<void> _setIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_indexKey, ids);
  }

  Future<bool> isDownloaded(String id) async {
    final ids = await _ids();
    return ids.contains(id);
  }

  // ---------- Save ----------

  Future<void> saveStory(StoryModel story) async {
    final item = OfflineItem(
      id: story.id,
      title: story.title,
      authorName: story.authorName,
      publicCode: story.publicCode,
      coverUrl: story.coverUrl,
      description: story.description,
      category: story.category,
      savedAt: DateTime.now(),
      contentBlocks: story.contentBlocks,
      kind: 'story',
    );
    await _write(item);
  }

  Future<void> saveEpisode({
    required String episodeId,
    required String novelTitle,
    required String episodeTitle,
    required int chapterNumber,
    required List<ContentBlockModel> contentBlocks,
    String? authorName,
    String? publicCode,
  }) async {
    final item = OfflineItem(
      id: 'ep_$episodeId',
      title: episodeTitle.isNotEmpty ? episodeTitle : 'পর্ব $chapterNumber',
      subtitle: novelTitle,
      authorName: authorName,
      publicCode: publicCode,
      savedAt: DateTime.now(),
      contentBlocks: contentBlocks,
      kind: 'episode',
    );
    await _write(item);
  }

  Future<void> _write(OfflineItem item) async {
    final f = await _file(item.id);
    await f.writeAsString(jsonEncode(item.toJson()));

    final ids = await _ids();
    if (!ids.contains(item.id)) {
      ids.insert(0, item.id);
      await _setIds(ids);
    }
  }

  // ---------- Read ----------

  Future<OfflineItem?> get(String id) async {
    final f = await _file(id);
    if (!await f.exists()) return null;
    try {
      final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return OfflineItem.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// পুরনো নামের alias
  Future<OfflineItem?> getStory(String id) => get(id);

  Future<List<OfflineItem>> listAll() async {
    final ids = await _ids();
    final list = <OfflineItem>[];
    for (final id in ids) {
      final item = await get(id);
      if (item != null) list.add(item);
    }
    return list;
  }

  // ---------- Remove ----------

  Future<void> remove(String id) async {
    final f = await _file(id);
    if (await f.exists()) await f.delete();
    final ids = await _ids();
    ids.remove(id);
    await _setIds(ids);
  }

  /// alias
  Future<void> removeStory(String id) => remove(id);

  Future<void> clearAll() async {
    final ids = await _ids();
    for (final id in ids) {
      final f = await _file(id);
      if (await f.exists()) await f.delete();
    }
    await _setIds([]);
  }
}
