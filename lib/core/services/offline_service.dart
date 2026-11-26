// lib/core/services/offline_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_block_model.dart';
import '../models/story_model.dart';

class OfflineItem {
  final String id;
  final String kind;
  final String title;
  final String? subtitle;
  final String? authorName;
  final String? publicCode;
  final String? novelId;
  final int? chapterNumber;
  final List<ContentBlockModel> contentBlocks;
  final DateTime savedAt;

  const OfflineItem({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.authorName,
    this.publicCode,
    this.novelId,
    this.chapterNumber,
    required this.contentBlocks,
    required this.savedAt,
  });

  factory OfflineItem.fromJson(Map<String, dynamic> json) {
    final blocks = <ContentBlockModel>[];
    final raw = json['content_blocks'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          blocks.add(ContentBlockModel.fromJson(item));
        } else if (item is Map) {
          blocks.add(
            ContentBlockModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return OfflineItem(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'story',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      authorName: json['author_name'] as String?,
      publicCode: json['public_code'] as String?,
      novelId: json['novel_id'] as String?,
      chapterNumber: (json['chapter_number'] as num?)?.toInt(),
      contentBlocks: blocks,
      savedAt: DateTime.tryParse(json['saved_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'title': title,
        'subtitle': subtitle,
        'author_name': authorName,
        'public_code': publicCode,
        'novel_id': novelId,
        'chapter_number': chapterNumber,
        'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
        'saved_at': savedAt.toIso8601String(),
      };

  StoryModel toStoryModel() {
    return StoryModel(
      id: id.startsWith('ep_') ? id.substring(3) : id,
      authorId: '',
      title: title,
      description: subtitle ?? '',
      contentBlocks: contentBlocks,
      publicCode: publicCode,
      isPublished: true,
      isDraft: false,
      createdAt: savedAt,
      updatedAt: savedAt,
      authorName: authorName,
    );
  }
}

class OfflineService {
  static const _indexKey = 'offline_item_ids';
  static const int _maxStorageMb = 500;

  Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/offline_content');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> _file(String id) async {
    final d = await _dir();
    final safe = id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return File('${d.path}/$safe.json');
  }

  Future<List<String>> _ids() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_indexKey) ?? [];
  }

  Future<void> _setIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_indexKey, ids);
  }

  Future<int> getCurrentStorageUsed() async {
    final dir = await _dir();
    int total = 0;
    if (!await dir.exists()) return 0;
    await for (final file in dir.list()) {
      if (file is File) {
        total += await file.length();
      }
    }
    return total;
  }

  Future<bool> isDownloaded(String id) async {
    final ids = await _ids();
    return ids.contains(id);
  }

  Future<void> _write(OfflineItem item) async {
    final currentBytes = await getCurrentStorageUsed();
    if (currentBytes > (_maxStorageMb * 1024 * 1024)) {
      throw Exception('storageFull');
    }

    final f = await _file(item.id);
    await f.writeAsString(jsonEncode(item.toJson()));

    final ids = await _ids();
    if (!ids.contains(item.id)) {
      ids.insert(0, item.id);
      await _setIds(ids);
    }
  }

  Future<void> saveStory(StoryModel story) async {
    final item = OfflineItem(
      id: story.id,
      kind: 'story',
      title: story.title,
      subtitle: story.description.isNotEmpty ? story.description : null,
      authorName: story.authorName,
      publicCode: story.publicCode,
      contentBlocks: story.contentBlocks,
      savedAt: DateTime.now(),
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
    String? novelId,
  }) async {
    final item = OfflineItem(
      id: 'ep_$episodeId',
      kind: 'episode',
      title: episodeTitle,
      subtitle: novelTitle,
      authorName: authorName,
      publicCode: publicCode,
      novelId: novelId,
      chapterNumber: chapterNumber,
      contentBlocks: contentBlocks,
      savedAt: DateTime.now(),
    );
    await _write(item);
  }

  Future<OfflineItem?> get(String id) async {
    final f = await _file(id);
    if (!await f.exists()) return null;
    try {
      final map = jsonDecode(await f.readAsString());
      if (map is Map<String, dynamic>) return OfflineItem.fromJson(map);
      if (map is Map) {
        return OfflineItem.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (_) {}
    return null;
  }

  Future<List<OfflineItem>> listAll() async {
    final ids = await _ids();
    final out = <OfflineItem>[];
    for (final id in ids) {
      final item = await get(id);
      if (item != null) out.add(item);
    }
    return out;
  }

  // ✅ ফাইল থাকলে ডিলিট হবে
  Future<void> remove(String id) async {
    final f = await _file(id);
    if (await f.exists()) await f.delete(); 
    final ids = await _ids();
    ids.remove(id);
    await _setIds(ids);
  }

  Future<void> clearAll() async {
    final ids = await _ids();
    for (final id in ids) {
      final f = await _file(id);
      if (await f.exists()) await f.delete();
    }
    await _setIds([]);
  }
}
