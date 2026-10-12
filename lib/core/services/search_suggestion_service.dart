// lib/core/services/search_suggestion_service.dart
// Local frequency — সবচেয়ে বেশি সার্চ সাজেশন

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SearchSuggestionService {
  static const _freqKey = 'search_freq_v1';
  static const _recentKey = 'search_recent';

  /// সার্চ সফল/সাবমিট হলে কল করুন
  Future<void> recordQuery(String raw) async {
    final q = raw.trim();
    if (q.length < 2) return;

    final prefs = await SharedPreferences.getInstance();

    // frequency map
    final map = _readFreq(prefs);
    map[q] = (map[q] ?? 0) + 1;
    await prefs.setString(_freqKey, jsonEncode(map));

    // recent list (আগের লজিকের সাথে সামঞ্জস্য)
    final list = prefs.getStringList(_recentKey) ?? [];
    list.remove(q);
    list.insert(0, q);
    if (list.length > 10) list.removeRange(10, list.length);
    await prefs.setStringList(_recentKey, list);
  }

  /// count বেশি আগে — top N
  Future<List<String>> topQueries({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readFreq(prefs);
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  Future<List<String>> recent({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    return list.take(limit).toList();
  }

  Future<void> clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }

  Map<String, int> _readFreq(SharedPreferences prefs) {
    final raw = prefs.getString(_freqKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }
}
