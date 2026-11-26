class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const String profiles = 'profiles';
  static const String stories = 'stories';
  static const String novels = 'novels';
  static const String episodes = 'episodes';
  static const String comments = 'comments';
  static const String commentLikes = 'comment_likes';
  static const String reactions = 'reactions';
  static const String bookmarks = 'bookmarks';
  static const String follows = 'follows';
  static const String contentViews = 'content_views';
  static const String appSettings = 'app_settings';
  static const String reports = 'reports';
  static const String notifications = 'notifications';
  static const String videoPosts = 'video_posts';
  static const String videoSaves = 'video_saves';
  
  static const String rpcRecordView = 'record_view';
}
