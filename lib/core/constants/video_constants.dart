/// ভিডিও লিমিট ও সেটিংস
class VideoConstants {
  VideoConstants._();

  /// সর্বোচ্চ ১৫ মিনিট
  static const int maxDurationSeconds = 15 * 60; 

  /// সর্বোচ্চ সাইজ ৫০ MB
  static const int maxSizeBytes = 50 * 1024 * 1024; 

  /// অ্যালাউড ফরম্যাট
  static const List<String> allowedMimeTypes = [
    'video/mp4',
    'video/quicktime', // .mov
  ];

  /// Message keys (UI-তে l10n দিয়ে translate হবে)
  static const String maxDurationMessageKey = 'videoTooLong';
  static const String featureOffMessageKey = 'videoFeatureDisabled';

  /// অ্যাডমিন সেটিং কী
  static const String settingsKeyFeature = 'video_feature';
  static const String settingsKeyLimits = 'video_limits';
}
