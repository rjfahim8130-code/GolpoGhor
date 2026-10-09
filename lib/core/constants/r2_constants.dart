/// Access/Secret শুধু dart-define — GitHub-এ খালি থাকবে।
class R2Constants {
  R2Constants._();

  static const String accountId = 'da2f491c877caf8993d4025af453c094';
  static const String bucketName = 'golpoghor-storage';

  static const String accessKeyId = String.fromEnvironment(
    'R2_ACCESS_KEY',
    defaultValue: '',
  );
  static const String secretAccessKey = String.fromEnvironment(
    'R2_SECRET_KEY',
    defaultValue: '',
  );

  static const String publicBaseUrl =
      'https://pub-efbbde8c54e344e2a29cd3bc79867d4a.r2.dev';

  static bool get isConfigured =>
      accountId.isNotEmpty &&
      accessKeyId.isNotEmpty &&
      secretAccessKey.isNotEmpty &&
      publicBaseUrl.isNotEmpty;

  static String get endpoint => 'https://$accountId.r2.cloudflarestorage.com';

  static const String folderStories = 'stories';
  static const String folderNovels = 'novels';
  static const String folderEpisodes = 'episodes';
  static const String folderVideos = 'videos';
  static const String folderAvatars = 'avatars';
  static const String folderCovers = 'covers';
}
