import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/novel_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';

class SearchResult {
  final List<UserModel> authors;
  final List<StoryModel> stories;
  final List<NovelModel> novels;
  final List<VideoModel> videos;
  final StoryModel? exactStoryCode;
  final NovelModel? exactNovelCode;
  final UserModel? exactUserCode;

  const SearchResult({
    this.authors = const [],
    this.stories = const [],
    this.novels = const [],
    this.videos = const [],
    this.exactStoryCode,
    this.exactNovelCode,
    this.exactUserCode,
  });

  bool get isEmpty =>
      authors.isEmpty &&
      stories.isEmpty &&
      novels.isEmpty &&
      videos.isEmpty &&
      exactStoryCode == null &&
      exactNovelCode == null &&
      exactUserCode == null;
}

class SearchService {
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic> _withAuthor(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final p = map['profiles'];
    if (p is Map) {
      map['author_name'] = p['full_name'];
      map['author_username'] = p['username'];
      map['author_avatar'] = p['avatar_url'];
    }
    return map;
  }

  Future<SearchResult> search(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) return const SearchResult();

    StoryModel? exactStory;
    NovelModel? exactNovel;
    UserModel? exactUser;

    final code = q.toUpperCase();
    final pattern = '%$q%';

    // Exact codes
    try {
      final s = await _client
          .from(SupabaseConstants.stories)
          .select('*, profiles:author_id (full_name, username, avatar_url)')
          .or('public_code.eq.$code,public_code.ilike.$q')
          .eq('is_published', true)
          .limit(1)
          .maybeSingle();
      if (s != null) {
        exactStory = StoryModel.fromJson(
          _withAuthor(Map<String, dynamic>.from(s)),
        );
      }
    } catch (_) {}

    try {
      final n = await _client
          .from(SupabaseConstants.novels)
          .select('*, profiles:author_id (full_name, username, avatar_url)')
          .or('public_code.eq.$code,public_code.ilike.$q')
          .eq('is_published', true)
          .limit(1)
          .maybeSingle();
      if (n != null) {
        exactNovel = NovelModel.fromJson(
          _withAuthor(Map<String, dynamic>.from(n)),
        );
      }
    } catch (_) {}

    try {
      final uname = q.replaceAll('@', '');
      final u = await _client
          .from(SupabaseConstants.profiles)
          .select()
          .or('username.ilike.$uname,invite_code.ilike.$code')
          .limit(1)
          .maybeSingle();
      if (u != null) {
        exactUser = UserModel.fromJson(Map<String, dynamic>.from(u));
      }
    } catch (_) {}

    // Partial — stories
    List<StoryModel> stories = [];
    try {
      final data = await _client
          .from(SupabaseConstants.stories)
          .select('*, profiles:author_id (full_name, username, avatar_url)')
          .eq('is_published', true)
          .eq('is_draft', false)
          .or('title.ilike.$pattern,description.ilike.$pattern,category.ilike.$pattern')
          .order('view_count', ascending: false)
          .limit(20);
      stories = (data as List)
          .map((e) => StoryModel.fromJson(
                _withAuthor(Map<String, dynamic>.from(e as Map)),
              ))
          .where((s) => exactStory == null || s.id != exactStory!.id)
          .toList();
    } catch (_) {}

    // Partial — novels
    List<NovelModel> novels = [];
    try {
      final data = await _client
          .from(SupabaseConstants.novels)
          .select('*, profiles:author_id (full_name, username, avatar_url)')
          .eq('is_published', true)
          .eq('is_draft', false)
          .or('title.ilike.$pattern,description.ilike.$pattern,category.ilike.$pattern')
          .order('view_count', ascending: false)
          .limit(15);
      novels = (data as List)
          .map((e) => NovelModel.fromJson(
                _withAuthor(Map<String, dynamic>.from(e as Map)),
              ))
          .where((n) => exactNovel == null || n.id != exactNovel!.id)
          .toList();
    } catch (_) {}

    // Partial — authors
    List<UserModel> authors = [];
    try {
      final uname = q.replaceAll('@', '');
      final data = await _client
          .from(SupabaseConstants.profiles)
          .select()
          .or('username.ilike.%$uname%,full_name.ilike.$pattern')
          .limit(12);
      authors = (data as List)
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((u) => exactUser == null || u.id != exactUser!.id)
          .toList();
    } catch (_) {}

    // Partial — videos (fail হলে খালি)
    List<VideoModel> videos = [];
    try {
      final data = await _client
          .from(SupabaseConstants.videoPosts)
          .select('*, profiles:author_id (full_name, username, avatar_url)')
          .eq('is_published', true)
          .eq('is_draft', false)
          .or('title.ilike.$pattern,description.ilike.$pattern,series_title.ilike.$pattern')
          .order('view_count', ascending: false)
          .limit(15);
      videos = (data as List)
          .map((e) => VideoModel.fromJson(
                _withAuthor(Map<String, dynamic>.from(e as Map)),
              ))
          .toList();
    } catch (_) {}

    return SearchResult(
      authors: authors,
      stories: stories,
      novels: novels,
      videos: videos,
      exactStoryCode: exactStory,
      exactNovelCode: exactNovel,
      exactUserCode: exactUser,
    );
  }
}
