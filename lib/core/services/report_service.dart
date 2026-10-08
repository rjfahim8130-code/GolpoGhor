import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  /// targetType: story | episode | novel | user | comment
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
}
