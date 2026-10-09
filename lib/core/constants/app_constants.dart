class AppConstants {
  AppConstants._();

  static const String appName = 'গল্পঘর';
  static const String appNameEn = 'GolpoGhor';
  static const String appVersion = '1.0.0';

  // ক্যাটাগরি
  static const List<String> categories = [
    'প্রেম',
    'রহস্য',
    'হরর',
    'সামাজিক',
    'ইতিহাস',
    'কমেডি',
    'কিশোর',
    'অন্যান্য',
  ];

  // রিঅ্যাকশন টাইপ
  static const List<String> reactionTypes = [
    'like',
    'love',
    'wow',
    'sad',
    'fire',
  ];

  // পেজিনেশন
  static const int feedPageSize = 15;
  static const int listPageSize = 20;

  // Search
  static const int searchDebounceMs = 300;
  static const int searchRecentMax = 10;

  // Reader
  static const double readerLogoOpacity = 0.10;
  static const double minFontScale = 0.55;
  static const double maxFontScale = 1.50;
  static const double defaultFontScale = 0.95;
  static const double fontScaleStep = 0.08;

  // Notification (in-app)
  static const int notificationRetentionDays = 2;
  static const int notificationPageSize = 30;

  // Comment
  static const int commentMaxLength = 1000;
  static const int reportReasonMaxLength = 500;
}
