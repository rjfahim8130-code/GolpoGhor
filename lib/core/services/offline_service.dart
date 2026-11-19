// lib/core/services/offline_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_block_model.dart';
import '../models/story_model.dart';

class OfflineItem {
  // ... (আগের মতোই থাকবে)
}

class OfflineService {
  static const _indexKey = 'offline_item_ids';
  static const int _maxStorageMb = 500; // সর্বোচ্চ ৫০০ মেগাবাইট

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

  Future<int> getCurrentStorageUsed() async {
    final dir = await _dir();
    int total = 0;
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
    // চেক করা (যদি ৫০০MB ক্রস করে, তবে এরর দেবে)
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

  // ... (saveStory, saveEpisode, get, listAll আগের মতোই থাকবে)

  Future<void> remove(String id) async {
    final f = await _file(id);
    if (await f.exists()) await f.delete();
    final ids = await _ids();
    ids.remove(id);
    await _setIds(ids);
  }
}
