/// R2 public config only. Access/Secret live in Supabase Edge Function secrets.
class R2Constants {
  R2Constants._();

  static const String accountId = String.fromEnvironment(
    'R2_ACCOUNT_ID',
    defaultValue: '',
  );

  static const String bucketName = String.fromEnvironment(
    'R2_BUCKET',
    defaultValue: 'golpoghor',
  );

  static const String publicBaseUrl = String.fromEnvironment(
    'R2_PUBLIC_BASE_URL',
    defaultValue: '',
  );

  /// Client no longer needs access/secret. Kept empty for safety.
  static const String accessKeyId = '';
  static const String secretAccessKey = '';

  static bool get isPublicConfigured =>
      publicBaseUrl.isNotEmpty && accountId.isNotEmpty;

  static const String folderStories = 'stories';
  static const String folderNovels = 'novels';
  static const String folderEpisodes = 'episodes';
  static const String folderVideos = 'videos';
  static const String folderAvatars = 'avatars';
  static const String folderCovers = 'covers';
}
