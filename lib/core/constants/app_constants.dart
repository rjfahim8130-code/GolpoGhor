class AppConstants {
  AppConstants._();

  static const String appName = 'গল্পঘর';
  static const String appNameEn = 'GolpoGhor';
  static const String appVersion = '1.0.1';

  static const List<String> categoryKeys = [
    'catRomance', 'catMystery', 'catHorror', 'catSocial',
    'catHistory', 'catComedy', 'catTeen', 'catOther',
  ];

  static const List<String> reactionTypes = ['like', 'love', 'wow', 'sad', 'fire'];

  static const int feedPageSize = 15;
  static const int listPageSize = 20;

  static const int searchDebounceMs = 300;
  static const int searchRecentMax = 10;

  static const double readerLogoOpacity = 0.10;
  static const double minFontScale = 0.55;
  static const double maxFontScale = 1.50;
  static const double defaultFontScale = 0.95;
  static const double fontScaleStep = 0.08;

  static const int notificationRetentionDays = 2;
  static const int notificationPageSize = 30;

  static const int commentMaxLength = 1000;
  static const int reportReasonMaxLength = 500;

  static const int maxUploadImageMb = 5;
  static const int maxUploadVideoMb = 50;
  static const int apiTimeoutSeconds = 30;
}
