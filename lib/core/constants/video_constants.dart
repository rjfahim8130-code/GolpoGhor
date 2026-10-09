/// ভিডিও লিমিট ও সেটিংস কী
class VideoConstants {
  VideoConstants._();

  /// সর্বোচ্চ ১৫ মিনিট
  static const int maxDurationSeconds = 15 * 60; // 900

  static const String maxDurationMessage =
      'ভিডিও সর্বোচ্চ ১৫ মিনিট হতে পারবে। আরও ছোট করে আবার চেষ্টা করুন।';

  static const String featureOffMessage = 'ভিডিও ফিচার এখন বন্ধ আছে।';

  /// অ্যাডমিন সেটিং কী
  static const String settingsKeyFeature = 'video_feature';
  static const String settingsKeyLimits = 'video_limits';
}
