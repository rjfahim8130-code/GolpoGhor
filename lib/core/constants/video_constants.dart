/// ভিডিও লিমিট ও সেটিংস কী
/// 
/// নোট: বাংলা message গুলো এখানে রাখা হবে না।
/// UI-তে l10n.videoTooLong / l10n.videoFeatureDisabled ব্যবহার করুন।
class VideoConstants {
  VideoConstants._();

  /// সর্বোচ্চ ১৫ মিনিট
  static const int maxDurationSeconds = 15 * 60; // 900

  /// Message keys (UI-তে l10n দিয়ে translate হবে)
  static const String maxDurationMessageKey = 'videoTooLong';
  static const String featureOffMessageKey = 'videoFeatureDisabled';

  /// অ্যাডমিন সেটিং কী
  static const String settingsKeyFeature = 'video_feature';
  static const String settingsKeyLimits = 'video_limits';
}
