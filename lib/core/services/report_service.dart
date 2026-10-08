import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<void> submit({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('লগইন নেই');
    final text = reason.trim();
    if (text.length < 5) throw Exception('কারণ কমপক্ষে ৫ অক্ষর লিখুন');

    await _client.from(SupabaseConstants.reports).insert({
      'reporter_id': uid,
      'target_type': targetType,
      'target_id': targetId,
      'reason': text,
      'status': 'open',
    });
  }

  Future<List<Map<String, dynamic>>> listOpen({int limit = 50}) async {
    final rows = await _client
        .from(SupabaseConstants.reports)
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> markReviewed(String reportId) async {
    await _client
        .from(SupabaseConstants.reports)
        .update({'status': 'reviewed'})
        .eq('id', reportId);
  }

  Future<void> dismiss(String reportId) async {
    await _client
        .from(SupabaseConstants.reports)
        .update({'status': 'dismissed'})
        .eq('id', reportId);
  }
}
