import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';
import '../models/novel_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../models/video_model.dart'; // নতুন ভিডিও মডেল ইমপোর্ট

class SearchResult {
  final List<UserModel> authors;
  final List<StoryModel> stories;
  final List<NovelModel> novels;
  final List<VideoModel> videos; // ভিডিও লিস্ট যোগ করা হলো
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

  Map<String, dynamic> _storyWithAuthor(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final profiles = map['profiles'];
    if (profiles is Map) {
      map['author_name'] = profiles['full_name'];
      map['author_username'] = profiles['username'];
      map['author_avatar'] = profiles['avatar_url'];
    }
    return map;
  }

  /// প্রফেশনাল সার্চ: কোড → ইউজারনেম → টাইটেল/নাম
  Future<SearchResult> search(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) return const SearchResult();
    if (q.length < 2 && !q.contains('-')) {
      // এক অক্ষরে শুধু কোড-স্টাইল হতে পারে
      if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(q)) {
        return const SearchResult();
      }
    }

    StoryModel? exactStory;
    NovelModel? exactNovel;
    UserModel? exactUser;

    final code = q.toUpperCase();

    // 1) নিখুঁত / কাছাকাছি কোড
    try {
      final s = await _client
          .from(SupabaseConstants.stories)
          .select('''
            *,
            profiles:author_id (full_name, username, avatar_url)
          ''')
          .or('public_code.eq.$code,public_code.ilike.$q')
          .eq('is_published', true)
          .limit(1)
          .maybeSingle();
      if (s != null) {
        exactStory = StoryModel.fromJson(
          _storyWithAuthor(Map<String, dynamic>.from(s)),
        );
      }
    } catch (_) {}

    try {
      final n = await _client
          .from(SupabaseConstants.novels)
          .select('''
            *,
            profiles:author_id (full_name, username, avatar_url)
          ''')
          .or('public_code.eq.$code,public_code.ilike.$q')
          .eq('is_published', true)
          .limit(1)
          .maybeSingle();
      if (n != null) {
        final map = Map<String, dynamic>.from(n);
        final profiles = map['profiles'];
        if (profiles is Map) {
          map['author_name'] = profiles['full_name'];
          map['author_username'] = profiles['username'];
          map['author_avatar'] = profiles['avatar_url'];
        }
        exactNovel = NovelModel.fromJson(map);
      }
    } catch (_) {}

    try {
      final u = await _client
          .from(SupabaseConstants.profiles)
          .select()
          .or('username.ilike.${q.replaceAll('@', '')},invite_code.ilike.$code')
          .limit(1)
          .maybeSingle();
      if (u != null) {
        exactUser = UserModel.fromJson(Map<String, dynamic>.from(u));
      }
    } catch (_) {}

    // 2) টাইটেল / নাম partial
    final pattern = '%$q%';

    List<StoryModel> stories = [];
    try {
      final data = await _client
          .from(SupabaseConstants.stories)
          .select('''
            *,
            profiles:author_id (full_name, username, avatar_url)
          ''')
          .eq('is_published', true)
          .eq('is_draft', false)
          .or('title.ilike.$pattern,description.ilike.$pattern,category.ilike.$pattern')
          .order('view_count', ascending: false)
          .limit(20);

      stories = (data as List)
          .map((e) => StoryModel.fromJson(
                _storyWithAuthor(Map<String, dynamic>.from(e as Map)),
              ))
          .where((s) => exactStory == null || s.id != exactStory!.id)
          .toList();
    } catch (_) {}

    List<NovelModel> novels = [];
    try {
      final data = await _client
          .from(SupabaseConstants.novels)
          .select('''
            *,
            profiles:author_id (full_name, username, avatar_url)
          ''')
          .eq('is_published', true)
          .eq('is_draft', false)
          .or('title.ilike.$pattern,description.ilike.$pattern,category.ilike.$pattern')
          .order('view_count', ascending: false)
          .limit(15);

      novels = (data as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final profiles = map['profiles'];
        if (profiles is Map) {
          map['author_name'] = profiles['full_name'];
          map['author_username'] = profiles['username'];
          map['author_avatar'] = profiles['avatar_url'];
        }
        return NovelModel.fromJson(map);
      }).where((n) => exactNovel == null || n.id != exactNovel!.id).toList();
    } catch (_) {}

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

    // 3) ভিডিও সার্চ লজিক
    List<VideoModel> videos = [];
    try {
      final data = await _client
          .from(SupabaseConstants.videoPosts)
          .select('''
            *,
            profiles:author_id (full_name, username, avatar_url)
          ''')
          .eq('is_published', true)
          .eq('is_draft', false)
          .or(
            'title.ilike.$pattern,description.ilike.$pattern,series_title.ilike.$pattern',
          )
          .order('view_count', ascending: false)
          .limit(15);

      videos = (data as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final p = map['profiles'];
        if (p is Map) {
          map['author_name'] = p['full_name'];
          map['author_username'] = p['username'];
          map['author_avatar'] = p['avatar_url'];
        }
        return VideoModel.fromJson(map);
      }).toList();
    } catch (_) {}

    return SearchResult(
      authors: authors,
      stories: stories,
      novels: novels,
      videos: videos, // ভিডিও রেজल्ट যুক্ত করা হলো
      exactStoryCode: exactStory,
      exactNovelCode: exactNovel,
      exactUserCode: exactUser,
    );
  }
}
