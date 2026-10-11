// lib/core/utils/time_ago.dart
// সংশোধিত: বাংলা + ইংরেজি দুই ভাষা

class TimeAgo {
  TimeAgo._();

  /// বাংলা version
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

  /// ইংরেজি version
  static String en(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// সংখ্যা সংক্ষেপে দেখানো
  /// - বাংলায়: হাজার, লক্ষ, কোটি
  /// - ইংরেজিতে: K, M, B
  static String compact(int n, {bool bn = true}) {
    if (bn) {
      if (n < 1000) return '$n';
      if (n < 100000) return '${(n / 1000).toStringAsFixed(1)} হাজার';
      if (n < 10000000) return '${(n / 100000).toStringAsFixed(1)} লক্ষ';
      return '${(n / 10000000).toStringAsFixed(1)} কোটি';
    } else {
      if (n < 1000) return '$n';
      if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}K';
      if (n < 1000000000) return '${(n / 1000000).toStringAsFixed(1)}M';
      return '${(n / 1000000000).toStringAsFixed(1)}B';
    }
  }
}
