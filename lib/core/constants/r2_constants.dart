/// R2 কনফিগারেশন
/// Access/Secret শুধু dart-define বা Edge Function থেকে আসবে।
class R2Constants {
  R2Constants._();

  // GitHub Secrets থেকে ডেটা নেবে
  static const String accountId = String.fromEnvironment(
    'R2_ACCOUNT_ID',
    defaultValue: 'da2f491c877caf8993d4025af453c094', // লোকাল টেস্টের জন্য ডিফল্ট
  );
  
  static const String bucketName = 'golpoghor'; // তোমার নতুন বাকেটের নাম

  // ০৭ নম্বরে Edge Function করলে এই Access/Secret অ্যাপ থেকে মুছে ফেলা হবে।
  static const String accessKeyId = String.fromEnvironment(
    'R2_ACCESS_KEY',
    defaultValue: '',
  );
  static const String secretAccessKey = String.fromEnvironment(
    'R2_SECRET_KEY',
    defaultValue: '',
  );

  static const String publicBaseUrl = String.fromEnvironment(
    'R2_PUBLIC_BASE_URL',
    defaultValue: 'https://pub-1be9d6427ca2453a84e51d5a7792bda3.r2.dev',
  );

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
