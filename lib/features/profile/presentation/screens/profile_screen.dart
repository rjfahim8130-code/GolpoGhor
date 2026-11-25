// lib/features/profile/presentation/screens/profile_screen.dart (Part 1)
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
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF242526);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

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
          _error = context.l10n.profileNotFound;
          _loading = false;
        });
        return;
      }

      final user = await _auth.getProfile(id);
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = context.l10n.profileNotFound;
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
        _error = context.l10n.loadFailed;
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
    final l10n = context.l10n;
    final code = u.inviteCode ?? '';
    await Share.share(
      '${u.displayName} — ${l10n.shareFollowOnApp}'
      '${code.isNotEmpty ? '\n${l10n.shareCodeLabel}: $code' : ''}\n#গল্পঘর',
    );
  }

  Future<void> _deleteStory(StoryModel s) async {
    final l10n = context.l10n;
    final ok = await _confirm(l10n.deleteStoryConfirm, s.title);
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
    final l10n = context.l10n;
    final ok = await _confirm(
      l10n.deleteNovelConfirm,
      '${n.title} ${l10n.deleteNovelConfirmBody}',
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
    final l10n = context.l10n;
    final ok = await _confirm(l10n.deleteVideoConfirm, l10n.cannotUndo);
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
              style: const TextStyle(color: _dangerColor),
            ),
          ),
        ],
      ),
    );
  }
  // lib/features/profile/presentation/screens/profile_screen.dart (Part 2)
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final cardBg = isDark ? _cardDark : _cardLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const LoadingView());
    }
    if (_error != null || _user == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          foregroundColor: primaryText,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: ErrorView(message: _error ?? l10n.problem, onRetry: _load),
      );
    }

    final u = _user!;

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
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
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
        color: _brandGreen,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: () {
                    const g =
                        String.fromEnvironment('GLOBAL_PROFILE_COVER_URL');
                    final has = g.trim().isNotEmpty;
                    return BoxDecoration(
                      color: has
                          ? null
                          : (isDark
                              ? const Color(0xFF242526)
                              : const Color(0xFFF0F2F5)),
                      image: has
                          ? DecorationImage(
                              image: NetworkImage(g.trim()),
                              fit: BoxFit.cover,
                            )
                          : null,
                    );
                  }(),
                ),
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                            ),
                            child: CachedAvatar(
                              userId: u.id,
                              imageUrl: u.avatarUrl,
                              name: u.displayName,
                              radius: 44,
                              tappable: false,
                            ),
                          ),
                          if (_isMe && _isAdmin)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _dangerColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bg, width: 2),
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        u.displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      if (u.hasNickname) ...[
                        const SizedBox(height: 2),
                        Text(
                          '"${u.displayNickname}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (_isMe && _isAdmin) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _dangerColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _dangerColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield,
                                size: 12,
                                color: _dangerColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _dangerColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (u.bio != null && u.bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            u.bio!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: 1.4,
                              fontSize: 14,
                              color: primaryText,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ProfileStatsCard(
                          userId: u.id,
                          followerCount: u.followerCount,
                          followingCount: u.followingCount,
                          totalViews: _totalViews,
                          totalReactions: _totalReactions,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isMe)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _following
                                    ? const Color(0xFF65676B)
                                    : _brandGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
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
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
              ],
            ),
            const SizedBox(height: 220),
            if (u.inviteCode != null && u.inviteCode!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _brandGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.myCode,
                              style: TextStyle(
                                  fontSize: 12, color: secondaryText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              u.inviteCode!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _brandGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyCode(u.inviteCode!),
                        icon: Icon(Icons.copy, color: primaryText),
                      ),
                      IconButton(
                        onPressed: _shareProfile,
                        icon: Icon(Icons.share_outlined, color: primaryText),
                      ),
                    ],
                  ),
                ),
              ),
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
                  onEditProfile: () => context.push(RouteNames.editProfile),
                ),
              ),
            if (_isMe && _isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Material(
                  color: _dangerColor.withValues(alpha: 0.1),
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
                              color: _dangerColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: _dangerColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.adminDashboard,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _dangerColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: _dangerColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tab,
                labelColor: _brandGreen,
                unselectedLabelColor: secondaryText,
                indicatorColor: _brandGreen,
                tabs: [
                  Tab(text: l10n.story),
                  Tab(text: l10n.novel),
                  if (_videoOn) Tab(text: l10n.video),
                ],
              ),
            ),
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
                    onDeleteStory:
                        _isMe ? (s) async => _deleteStory(s) : null,
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
                    onDeleteNovel:
                        _isMe ? (n) async => _deleteNovel(n) : null,
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
                      onDeleteVideo:
                          _isMe ? (v) async => _deleteVideo(v) : null,
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
