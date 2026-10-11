// lib/features/profile/presentation/screens/profile_screen.dart
// admin email-ভিত্তিক, nickname, ড্যাশবোর্ড UI

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/video_model.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/admin_service.dart';
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
  final _admin = AdminService();
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
  bool _isAdmin = false;

  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  List<VideoModel> _videos = [];

  int _totalViews = 0;
  int _totalReactions = 0;

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
        final cached = ref.read(sessionCacheProvider);
        if (cached != null) {
          if (!mounted) return;
          setState(() {
            _user = cached;
            _loading = false;
          });
          return;
        }
        if (!mounted) return;
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

      if (_isMe) {
        await ref.read(sessionCacheProvider.notifier).save(user);
      }

      bool following = false;
      if (!_isMe) {
        following = await _followService.isFollowing(user.id);
      }

      // এডমিন চেক — email-ভিত্তিক
      bool isAdmin = false;
      if (_isMe) {
        isAdmin = await _admin.isAdmin();
      }

      final videoOn = ref.read(videoFeatureProvider);

      final results = await Future.wait([
        _storyService.getByAuthor(user.id),
        _novelService.getByAuthor(user.id),
        if (videoOn)
          _videoService.getByAuthor(user.id)
        else
          Future<List<VideoModel>>.value(const []),
      ]);

      final stories = results[0] as List<StoryModel>;
      final novels = results[1] as List<NovelModel>;
      final videos = results[2] as List<VideoModel>;

      int totalViews = 0;
      int totalReactions = 0;
      for (final s in stories) {
        totalViews += s.viewCount;
        totalReactions += s.reactionCount;
      }
      for (final n in novels) {
        totalViews += n.viewCount;
        totalReactions += n.reactionCount;
      }
      for (final v in videos) {
        totalViews += v.viewCount;
        totalReactions += v.reactionCount;
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _following = following;
        _videoOn = videoOn;
        _isAdmin = isAdmin;
        _stories = stories;
        _novels = novels;
        _videos = videos;
        _totalViews = totalViews;
        _totalReactions = totalReactions;
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
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copied)),
    );
  }

  Future<void> _shareProfile() async {
    final u = _user;
    if (u == null) return;
    final code = u.inviteCode ?? '';
    await Share.share(
      '${u.displayName} — গল্পঘরে ফলো করুন\nকোড: $code\n#গল্পঘর',
    );
  }

  Future<void> _deleteStory(StoryModel s) async {
    final ok = await _confirm('গল্প মুছবেন?', s.title);
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
    final ok = await _confirm(
      'উপন্যাস মুছবেন?',
      '${n.title} এবং সব পর্ব মুছে যাবে',
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
    final ok = await _confirm('ভিডিও মুছবেন?', 'একেবারে মুছে যাবে');
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

  Future<bool?> _confirm(String title, String content) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
  
@override
Widget build(BuildContext context) {
  final l10n = context.l10n;
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
    drawer: _isMe
        ? AppMenuDrawer(
            userId: u.id,
            userName: u.displayName,
            userAvatar: u.avatarUrl,
            isAdmin: _isAdmin,
          )
        : null,
    appBar: AppBar(
      leading: widget.userId != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            )
          : null,
      title: Text(_isMe ? l10n.profile : u.displayName),
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
          // ---------------- হেডার ----------------
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CachedAvatar(
                      userId: u.id,
                      imageUrl: u.avatarUrl,
                      name: u.displayName,
                      radius: 44,
                      tappable: false,
                    ),
                    if (_isMe && _isAdmin)
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBg
                                  : AppColors.lightBg,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.shield,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
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

                if (u.hasNickname) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${u.displayNickname}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                if (_isMe && _isAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield,
                          size: 14,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
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

                ProfileStatsCard(
                  userId: u.id,
                  followerCount: u.followerCount,
                  followingCount: u.followingCount,
                  totalViews: _totalViews,
                  totalReactions: _totalReactions,
                ),

                const SizedBox(height: 16),

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
                              _following
                                  ? Icons.person_remove
                                  : Icons.person_add,
                            ),
                      label: Text(
                        _following ? l10n.unfollow : l10n.follow,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---------------- Invite Code ----------------
          if (u.inviteCode != null && u.inviteCode!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
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
            ),

          // ---------------- Quick actions ----------------
          if (_isMe)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ProfileQuickActions(
                videoOn: _videoOn,
                onNewStory: () => context.push(RouteNames.writeStory),
                onNewNovel: () => context.push(RouteNames.writeNovel),
                onNewVideo: _videoOn
                    ? () => context.push(RouteNames.createVideo)
                    : null,
                onEditProfile: () =>
                    context.push(RouteNames.editProfile),
              ),
            ),

          // ---------------- Admin shortcut ----------------
          if (_isMe && _isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Material(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push(RouteNames.admin),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.danger,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'অ্যাডমিন ড্যাশবোর্ড',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'আপনি সিস্টেম অ্যাডমিন',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
          
            // ---------------- TabBar ----------------
            Container(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: l10n.story),
                  Tab(text: l10n.novel),
                  if (_videoOn) Tab(text: l10n.video),
                ],
              ),
            ),

            // ---------------- TabBarView ----------------
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
}
