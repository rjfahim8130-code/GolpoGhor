class AppConstants {
  AppConstants._();

  static const String appName = 'গল্পঘর';
  static const String appNameEn = 'GolpoGhor';
  static const String appVersion = '1.0.0';

  // ক্যাটাগরি — locale-ভিত্তিক দেখাতে হবে
  // UI-তে l10n.categoryList ব্যবহার করুন
  // এই list শুধু DB-তে save করার জন্য (backend value)
  static const List<String> categoryKeys = [
    'catRomance',
    'catMystery',
    'catHorror',
    'catSocial',
    'catHistory',
    'catComedy',
    'catTeen',
    'catOther',
  ];

  // রিঅ্যাকশন টাইপ (locale-নিরপেক্ষ — emoji mapping)
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
