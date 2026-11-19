// lib/core/services/bookmark_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/novel_model.dart';
import '../models/story_model.dart';
import 'auth_service.dart';

class BookmarkService {
  final SupabaseClient _client = Supabase.instance.client;
  String? get _uid => _client.auth.currentUser?.id;

  // ... (isStoryBookmarked আগের মতোই)

  Future<bool> toggleStoryBookmark(String storyId) async {
    final uid = _uid;
    if (uid == null) throw AppException('notLoggedIn');
    // (আগের লজিক)
    return true;
  }

  // ... (বাকি মেথডগুলো আগের মতোই থাকবে, শুধু Exception গুলো AppException হবে)
}
