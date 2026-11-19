// lib/core/utils/time_ago.dart
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class TimeAgo {
  TimeAgo._();

  static String of(BuildContext context, DateTime dt) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 30) return l10n.timeJustNow;
    if (diff.inMinutes < 1) return '${diff.inSeconds} ${l10n.timeSecondsAgo}';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${l10n.timeMinutesAgo}';
    if (diff.inHours < 24) return '${diff.inHours} ${l10n.timeHoursAgo}';
    if (diff.inDays < 7) return '${diff.inDays} ${l10n.timeDaysAgo}';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} ${l10n.timeWeeksAgo}';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} ${l10n.timeMonthsAgo}';
    return '${(diff.inDays / 365).floor()} ${l10n.timeYearsAgo}';
  }

  static String compactOf(BuildContext context, int n) {
    final l10n = context.l10n;
    if (n < 1000) return '$n';
    if (n < 100000) return '${(n / 1000).toStringAsFixed(1)} ${l10n.compactThousand}';
    if (n < 10000000) return '${(n / 100000).toStringAsFixed(1)} ${l10n.compactLakh}';
    return '${(n / 10000000).toStringAsFixed(1)} ${l10n.compactCrore}';
  }

  // পুরনো ভার্সন (ব্যাকওয়ার্ড কম্প্যাটিবিলিটির জন্য)
  static String bn(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return 'এইমাত্র';
    if (diff.inMinutes < 1) return '${diff.inSeconds} সেকেন্ড আগে';
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
    if (diff.inDays < 7) return '${diff.inDays} দিন আগে';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} সপ্তাহ আগে';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} মাস আগে';
    return '${(diff.inDays / 365).floor()} বছর আগে';
  }
}
