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
    required this.writingWeek,
    required this.writingMonth,
    required this.writingPrevWeek,
    required this.writingPrevMonth,
    required this.videoWeek,
    required this.videoMonth,
    required this.videoPrevWeek,
    required this.videoPrevMonth,
  });
}

class InsightsService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  DateTime get _now => DateTime.now().toUtc();

  Future<InsightsBundle> loadMine() async {
    final uid = _uid;
    if (uid == null) {
      return const InsightsBundle(
        writingWeek: InsightsPeriodStats(),
        writingMonth: InsightsPeriodStats(),
        writingPrevWeek: InsightsPeriodStats(),
        writingPrevMonth: InsightsPeriodStats(),
        videoWeek: InsightsPeriodStats(),
        videoMonth: InsightsPeriodStats(),
        videoPrevWeek: InsightsPeriodStats(),
        videoPrevMonth: InsightsPeriodStats(),
      );
    }

    final now = _now;
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final week0 = DateTime.utc(weekStart.year, weekStart.month, weekStart.day);
    final prevWeek0 = week0.subtract(const Duration(days: 7));
    final month0 = DateTime.utc(now.year, now.month, 1);
    final prevMonth0 = DateTime.utc(now.year, now.month - 1, 1);

    final stories = await _client
        .from(SupabaseConstants.stories)
        .select('id, view_count, reaction_count, comment_count, created_at')
        .eq('author_id', uid);

    final novels = await _client
        .from(SupabaseConstants.novels)
        .select('id, view_count, reaction_count, created_at')
        .eq('author_id', uid);

    // episodes optional counts
    final episodes = await _client
        .from(SupabaseConstants.episodes)
        .select('id, view_count, reaction_count, comment_count, created_at, author_id')
        .eq('author_id', uid);

    List<Map<String, dynamic>> writingRows = [
      ...((stories as List).map((e) => Map<String, dynamic>.from(e as Map))),
      ...((novels as List).map((e) => Map<String, dynamic>.from(e as Map))),
      ...((episodes as List).map((e) => Map<String, dynamic>.from(e as Map))),
    ];

    List<Map<String, dynamic>> videoRows = [];
    try {
      final videos = await _client
          .from(SupabaseConstants.videoPosts)
          .select(
            'id, view_count, reaction_count, comment_count, save_count, created_at',
          )
          .eq('author_id', uid);
      videoRows = (videos as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
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
        // নোট: কাউন্ট মোট লাইফটাইম — পিরিয়ডে কনটেন্ট তৈরি হলে সেই কনটেন্টের মোট কাউন্ট
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

    final nextWeek = week0.add(const Duration(days: 7));
    final nextMonth = DateTime.utc(month0.year, month0.month + 1, 1);

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
