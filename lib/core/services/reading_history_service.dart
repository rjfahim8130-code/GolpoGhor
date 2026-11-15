// lib/core/services/reading_history_service.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ReadingHistoryItem {
  final String id;        // story id বা ep_<episodeId>
  final String title;
  final String? author;
  final String? coverUrl;
  final String kind;      // story | episode
  final double progress;  // 0.0 - 1.0
  final DateTime lastReadAt;

  ReadingHistoryItem({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    required this.kind,
    this.progress = 0,
    required this.lastReadAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'cover_url': coverUrl,
        'kind': kind,
        'progress': progress,
        'last_read_at': lastReadAt.toIso8601String(),
      };

  factory ReadingHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      author: json['author'] as String?,
      coverUrl: json['cover_url'] as String?,
      kind: json['kind'] as String? ?? 'story',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      lastReadAt: DateTime.tryParse(json['last_read_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ReadingHistoryService {
  static const _key = 'reading_history_v1';
  static const int _maxItems = 50;

  Future<List<ReadingHistoryItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ReadingHistoryItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList()
        ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> record({
    required String id,
    required String title,
    String? author,
    String? coverUrl,
    required String kind,
    double progress = 0,
  }) async {
    final items = await getAll();
    items.removeWhere((e) => e.id == id);
    items.insert(
      0,
      ReadingHistoryItem(
        id: id,
        title: title,
        author: author,
        coverUrl: coverUrl,
        kind: kind,
        progress: progress,
        lastReadAt: DateTime.now(),
      ),
    );
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }
    await _save(items);
  }

  Future<void> updateProgress(String id, double progress) async {
    final items = await getAll();
    final idx = items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final item = items[idx];
    items[idx] = ReadingHistoryItem(
      id: item.id,
      title: item.title,
      author: item.author,
      coverUrl: item.coverUrl,
      kind: item.kind,
      progress: progress,
      lastReadAt: DateTime.now(),
    );
    await _save(items);
  }

  Future<void> remove(String id) async {
    final items = await getAll();
    items.removeWhere((e) => e.id == id);
    await _save(items);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<ReadingHistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
