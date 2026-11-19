// lib/core/services/report_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/supabase_constants.dart';
import 'auth_service.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;

  Future<void> submit({required String targetType, required String targetId, required String reason}) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');

    final text = reason.trim();
    if (text.length < 5) throw AppException('reasonMinFive');
    if (text.length > AppConstants.reportReasonMaxLength) throw AppException('reasonTooLong');

    // ডুপ্লিকেট রিপোর্ট চেক
    final existing = await _client
        .from(SupabaseConstants.reports)
        .select('id')
        .eq('reporter_id', uid)
        .eq('target_type', targetType)
        .eq('target_id', targetId)
        .maybeSingle();

    if (existing != null) {
      throw AppException('alreadyReported'); // l10n এ মেসেজ দিতে হবে
    }

    await _client.from(SupabaseConstants.reports).insert({
      'reporter_id': uid,
      'target_type': targetType,
      'target_id': targetId,
      'reason': text,
      'status': 'open',
    });
  }

  // ... (listOpen, markReviewed, dismiss আগের মতোই)
}
