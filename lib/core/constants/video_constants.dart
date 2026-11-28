class VideoConstants {
  VideoConstants._();

  static const int maxDurationSeconds = 15 * 60; 
  static const int maxSizeBytes = 50 * 1024 * 1024; 

  static const List<String> allowedMimeTypes = ['video/mp4', 'video/quicktime'];

  static const String maxDurationMessageKey = 'videoTooLong';
  static const String featureOffMessageKey = 'videoFeatureDisabled';

  static const String settingsKeyFeature = 'video_feature';
  static const String settingsKeyLimits = 'video_limits';
}
