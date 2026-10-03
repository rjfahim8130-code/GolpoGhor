import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_block_model.dart';
import '../models/story_model.dart';

class OfflineStoryItem {
  final String id;
  final String title;
  final String? authorName;
  final String? publicCode;
  final String? coverUrl;
  final DateTime savedAt;
  final List<ContentBlockModel> contentBlocks;
  final String? description;
  final String? category;

  OfflineStoryItem({
    required this.id,
    required this.title,
    this.authorName,
    this.publicCode,
    this.coverUrl,
    required this.savedAt,
    required this.contentBlocks,
    this.description,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author_name': authorName,
        'public_code': publicCode,
        'cover_url': coverUrl,
        'saved_at': savedAt.toIso8601String(),
        'description': description,
        'category': category,
        'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
      };

  factory OfflineStoryItem.fromJson(Map<String, dynamic> json) {
    final blocks = <ContentBlockModel>[];
    final raw = json['content_blocks'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          blocks.add(
            ContentBlockModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return OfflineStoryItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      authorName: json['author_name'] as String?,
      publicCode: json['public_code'] as String?,
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      savedAt: DateTime.tryParse(json['saved_at']?.toString() ?? '') ??
          DateTime.now(),
      contentBlocks: blocks,
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
  static const _indexKey = 'offline_story_ids';

  Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/offline_stories');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> _file(String storyId) async {
    final d = await _dir();
    return File('${d.path}/$storyId.json');
  }

  Future<List<String>> _ids() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_indexKey) ?? [];
  }

  Future<void> _setIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_indexKey, ids);
  }

  Future<bool> isDownloaded(String storyId) async {
    final ids = await _ids();
    return ids.contains(storyId);
  }

  Future<void> saveStory(StoryModel story) async {
    final item = OfflineStoryItem(
      id: story.id,
      title: story.title,
      authorName: story.authorName,
      publicCode: story.publicCode,
      coverUrl: story.coverUrl,
      description: story.description,
      category: story.category,
      savedAt: DateTime.now(),
      contentBlocks: story.contentBlocks,
    );
    final f = await _file(story.id);
    await f.writeAsString(jsonEncode(item.toJson()));

    final ids = await _ids();
    if (!ids.contains(story.id)) {
      ids.insert(0, story.id);
      await _setIds(ids);
    }
  }

  Future<OfflineStoryItem?> getStory(String storyId) async {
    final f = await _file(storyId);
    if (!await f.exists()) return null;
    try {
      final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return OfflineStoryItem.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<List<OfflineStoryItem>> listAll() async {
    final ids = await _ids();
    final list = <OfflineStoryItem>[];
    for (final id in ids) {
      final item = await getStory(id);
      if (item != null) list.add(item);
    }
    return list;
  }

  Future<void> remove(String storyId) async {
    final f = await _file(storyId);
    if (await f.exists()) await f.delete();
    final ids = await _ids();
    ids.remove(storyId);
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
