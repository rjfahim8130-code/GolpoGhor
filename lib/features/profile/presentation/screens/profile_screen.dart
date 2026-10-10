import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/video_model.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../widgets/profile_posts_tab.dart';
import '../widgets/profile_quick_actions.dart';
import '../widgets/profile_stats_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _followService = FollowService();
  final _storyService = StoryService();
  final _novelService = NovelService();
  final _videoService = VideoService();

  late TabController _tab;

  UserModel? _user;
  bool _loading = true;
  String? _error;
  bool _isMe = true;
  bool _following = false;
  bool _followBusy = false;
  bool _videoOn = false;

  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  List<VideoModel> _videos = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final myId = _auth.currentUser?.id;
      final id = widget.userId ?? myId;
      _isMe = id != null && id == myId;

      if (id == null) {
        // অফলাইন বা লগইন নেই — cache থেকে দেখাও
        final cached = ref.read(sessionCacheProvider);
        if (cached != null) {
          if (!mounted) return;
          setState(() {
            _user = cached;
            _loading = false;
          });
          return;
        }
        setState(() {
          _error = 'প্রোফাইল পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }

      final user = await _auth.getProfile(id);
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'প্রোফাইল পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }

      // নিজের হলে cache update
      if (_isMe) {
        await ref.read(sessionCacheProvider.notifier).save(user);
      }

      bool following = false;
      if (!_isMe) {
        following = await _followService.isFollowing(user.id);
      }

      // video toggle check
      final videoOn = ref.read(videoFeatureProvider);

      // পোস্ট লোড (parallel)
      final results = await Future.wait([
        _storyService.getByAuthor(user.id),
        _novelService.getByAuthor(user.id),
        if (videoOn)
          _videoService.getByAuthor(user.id)
        else
          Future<List<VideoModel>>.value(const []),
      ]);

      if (!mounted) return;
      setState(() {
        _user = user;
        _following = following;
        _videoOn = videoOn;
        _stories = results[0] as List<StoryModel>;
        _novels = results[1] as List<NovelModel>;
        _videos = results[2] as List<VideoModel>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final u = _user;
    if (u == null || _isMe) return;
    setState(() => _followBusy = true);
    try {
      final on = await _followService.toggleFollow(u.id);
      final refreshed = await _auth.getProfile(u.id);
      if (!mounted) return;
      setState(() {
        _following = on;
        if (refreshed != null) _user = refreshed;
        _followBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _followBusy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('কোড কপি হয়েছে')),
    );
  }

  Future<void> _shareProfile() async {
    final u = _user;
    if (u == null) return;
    final code = u.inviteCode ?? u.username ?? '';
    await Share.share(
      '${u.displayName} — গল্পঘরে ফলো করুন\nকোড: $code\n#গল্পঘর',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const LoadingView());
    }
    if (_error != null || _user == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'সমস্যা', onRetry: _load),
      );
    }

    final u = _user!;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      // নিজের হলে ড্রয়ার খুলবে
      drawer: _isMe
          ? AppMenuDrawer(
              userId: u.id,
              userName: u.displayName,
              userAvatar: u.avatarUrl,
              isAdmin: u.isAdmin,
            )
          : null,
      appBar: AppBar(
        leading: widget.userId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(_isMe ? 'প্রোফাইল' : u.displayName),
        actions: [
          if (_isMe)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(RouteNames.settings),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // হেডার
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Column(
                children: [
                  CachedAvatar(
                    userId: u.id,
                    imageUrl: u.avatarUrl,
                    name: u.displayName,
                    radius: 44,
                    tappable: false,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    u.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (u.username != null && u.username!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${u.username}',
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                  ],
                  if (u.bio != null && u.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      u.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1.4, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Stats
                  ProfileStatsCard(
                    userId: u.id,
                    followerCount: u.followerCount,
                    followingCount: u.followingCount,
                    postCount:
                        _stories.length + _novels.length + _videos.length,
                  ),

                  const SizedBox(height: 16),

                  // Follow/Unfollow
                  if (!_isMe)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _following
                              ? Colors.grey.shade600
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _followBusy ? null : _toggleFollow,
                        icon: _followBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _following ? Icons.person_remove : Icons.person_add,
                              ),
                        label: Text(_following ? 'আনফলো' : 'ফলো'),
                      ),
                    ),
                ],
              ),
            ),
            
            // কোড + প্রাইমারি অ্যাকশন
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // invite code
                  if (u.inviteCode != null && u.inviteCode!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'আমার কোড',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  u.inviteCode!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyCode(u.inviteCode!),
                            icon: const Icon(Icons.copy),
                          ),
                          IconButton(
                            onPressed: _shareProfile,
                            icon: const Icon(Icons.share_outlined),
                          ),
                        ],
                      ),
                    ),

                  // প্রাইমারি ৪ বাটন (নিজের হলে)
                  if (_isMe)
                    ProfileQuickActions(
                      videoOn: _videoOn,
                      onNewStory: () =>
                          context.push(RouteNames.writeStory),
                      onNewNovel: () =>
                          context.push(RouteNames.writeNovel),
                      onNewVideo: _videoOn
                          ? () => context.push(RouteNames.createVideo)
                          : null,
                      onEditProfile: () =>
                          context.push(RouteNames.editProfile),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // TabBar
            Container(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: [
                  const Tab(text: 'গল্প'),
                  const Tab(text: 'উপন্যাস'),
                  if (_videoOn) const Tab(text: 'ভিডিও'),
                ],
              ),
            ),

            // TabBarView — fixed height, তবে inner scroll
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tab,
                children: [
                  ProfilePostsTab.stories(
                    stories: _stories,
                    onOpenStory: (s) =>
                        context.push('${RouteNames.story}/${s.id}'),
                    onEditStory: _isMe
                        ? (s) => context.push(
                              '${RouteNames.writeStory}/${s.id}',
                            )
                        : null,
                    onDeleteStory: _isMe
                        ? (s) async => _deleteStory(s)
                        : null,
                  ),
                  ProfilePostsTab.novels(
                    novels: _novels,
                    onOpenNovel: (n) =>
                        context.push('${RouteNames.novel}/${n.id}'),
                    onEditNovel: _isMe
                        ? (n) => context.push(
                              '${RouteNames.writeNovel}/${n.id}',
                            )
                        : null,
                    onDeleteNovel: _isMe
                        ? (n) async => _deleteNovel(n)
                        : null,
                  ),
                  if (_videoOn)
                    ProfilePostsTab.videos(
                      videos: _videos,
                      onOpenVideo: (v) => context.push(
                        Uri(
                          path: RouteNames.videos,
                          queryParameters: {'focus': v.id},
                        ).toString(),
                      ),
                      onEditVideo: _isMe
                          ? (v) => context.push(
                                '${RouteNames.createVideo}/${v.id}',
                              )
                          : null,
                      onDeleteVideo: _isMe
                          ? (v) async => _deleteVideo(v)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Delete helpers ----------

  Future<void> _deleteStory(StoryModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('গল্প মুছবেন?'),
        content: Text(s.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'মুছুন',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _storyService.deleteStory(s.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteNovel(NovelModel n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('উপন্যাস মুছবেন?'),
        content: Text('${n.title} এবং সব পর্ব মুছে যাবে'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'মুছুন',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _novelService.deleteNovel(n.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteVideo(VideoModel v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ভিডিও মুছবেন?'),
        content: const Text('একেবারে মুছে যাবে'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'মুছুন',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _videoService.deleteVideo(v.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
