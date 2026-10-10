import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

class InsightsPeriodStats {
  final int views;
  final int reactions;
  final int comments;
  final int saves;

  const InsightsPeriodStats({
    this.views = 0,
    this.reactions = 0,
    this.comments = 0,
    this.saves = 0,
  });

  static const empty = InsightsPeriodStats();
}

class InsightsBundle {
  final InsightsPeriodStats writingWeek;
  final InsightsPeriodStats writingMonth;
  final InsightsPeriodStats writingPrevWeek;
  final InsightsPeriodStats writingPrevMonth;
  final InsightsPeriodStats videoWeek;
  final InsightsPeriodStats videoMonth;
  final InsightsPeriodStats videoPrevWeek;
  final InsightsPeriodStats videoPrevMonth;

  const InsightsBundle({
    this.writingWeek = InsightsPeriodStats.empty,
    this.writingMonth = InsightsPeriodStats.empty,
    this.writingPrevWeek = InsightsPeriodStats.empty,
    this.writingPrevMonth = InsightsPeriodStats.empty,
    this.videoWeek = InsightsPeriodStats.empty,
    this.videoMonth = InsightsPeriodStats.empty,
    this.videoPrevWeek = InsightsPeriodStats.empty,
    this.videoPrevMonth = InsightsPeriodStats.empty,
  });
}

class InsightsService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  Future<InsightsBundle> loadMine() async {
    final uid = _uid;
    if (uid == null) return const InsightsBundle();

    final now = DateTime.now().toUtc();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final week0 = DateTime.utc(weekStart.year, weekStart.month, weekStart.day);
    final prevWeek0 = week0.subtract(const Duration(days: 7));
    final month0 = DateTime.utc(now.year, now.month, 1);
    final prevMonth0 = DateTime.utc(now.year, now.month - 1, 1);
    final nextWeek = week0.add(const Duration(days: 7));
    final nextMonth = DateTime.utc(month0.year, month0.month + 1, 1);

    // লেখা (গল্প + উপন্যাস + পর্ব)
    final writingRows = <Map<String, dynamic>>[];
    try {
      final s = await _client
          .from(SupabaseConstants.stories)
          .select('id, view_count, reaction_count, comment_count, created_at')
          .eq('author_id', uid);
      writingRows.addAll(
        (s as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {}

    try {
      final n = await _client
          .from(SupabaseConstants.novels)
          .select('id, view_count, reaction_count, comment_count, created_at')
          .eq('author_id', uid);
      writingRows.addAll(
        (n as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {}

    try {
      final ep = await _client
          .from(SupabaseConstants.episodes)
          .select('id, view_count, reaction_count, comment_count, created_at')
          .eq('author_id', uid);
      writingRows.addAll(
        (ep as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {}

    // ভিডিও
    final videoRows = <Map<String, dynamic>>[];
    try {
      final v = await _client
          .from(SupabaseConstants.videoPosts)
          .select(
            'id, view_count, reaction_count, comment_count, save_count, created_at',
          )
          .eq('author_id', uid);
      videoRows.addAll(
        (v as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {}

    InsightsPeriodStats sum(
      List<Map<String, dynamic>> rows,
      DateTime from,
      DateTime to,
    ) {
      var views = 0, reactions = 0, comments = 0, saves = 0;
      for (final r in rows) {
        final created =
            DateTime.tryParse(r['created_at']?.toString() ?? '')?.toUtc();
        if (created == null) continue;
        if (created.isBefore(from) || !created.isBefore(to)) continue;
        views += (r['view_count'] as num?)?.toInt() ?? 0;
        reactions += (r['reaction_count'] as num?)?.toInt() ?? 0;
        comments += (r['comment_count'] as num?)?.toInt() ?? 0;
        saves += (r['save_count'] as num?)?.toInt() ?? 0;
      }
      return InsightsPeriodStats(
        views: views,
        reactions: reactions,
        comments: comments,
        saves: saves,
      );
    }

    return InsightsBundle(
      writingWeek: sum(writingRows, week0, nextWeek),
      writingPrevWeek: sum(writingRows, prevWeek0, week0),
      writingMonth: sum(writingRows, month0, nextMonth),
      writingPrevMonth: sum(writingRows, prevMonth0, month0),
      videoWeek: sum(videoRows, week0, nextWeek),
      videoPrevWeek: sum(videoRows, prevWeek0, week0),
      videoMonth: sum(videoRows, month0, nextMonth),
      videoPrevMonth: sum(videoRows, prevMonth0, month0),
    );
  }
}
