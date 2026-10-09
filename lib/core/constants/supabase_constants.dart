class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = 'https://tvfaclrmmkxbukawcziu.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2ZmFjbHJtbWt4YnVrYXdjeml1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwMjgwMDQsImV4cCI6MjEwNjYwNDAwNH0.-4Gzjv_soFqUzp913gNAsbgcqxMuhxlC1LhbiM-XT54';

  // Tables
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

  // Video
  static const String videoPosts = 'video_posts';
  static const String videoSaves = 'video_saves';

  // RPC
  static const String rpcRecordView = 'record_view';
}
