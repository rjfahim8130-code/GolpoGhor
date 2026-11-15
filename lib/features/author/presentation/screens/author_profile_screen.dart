// lib/features/author/presentation/screens/author_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../../../home/presentation/widgets/novel_card.dart';
import '../../../home/presentation/widgets/story_card.dart';

class AuthorProfileScreen extends StatefulWidget {
  final String userId;

  const AuthorProfileScreen({super.key, required this.userId});

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _follow = FollowService();
  final _story = StoryService();
  final _novel = NovelService();

  late TabController _tab;

  UserModel? _user;
  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  bool _loading = true;
  bool _following = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
      final user = await _auth.getProfile(widget.userId);
      if (user == null) {
        setState(() {
          _error = context.l10n.profileNotFound;
          _loading = false;
        });
        return;
      }
      final stories = await _story.getByAuthor(widget.userId);
      final novels = await _novel.getByAuthor(widget.userId);
      bool following = false;
      final myId = _auth.currentUser?.id;
      if (myId != null && myId != widget.userId) {
        following = await _follow.isFollowing(widget.userId);
      }
      if (!mounted) return;
      setState(() {
        _user = user;
        _stories = stories;
        _novels = novels;
        _following = following;
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
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final on = await _follow.toggleFollow(widget.userId);
      if (!mounted) return;
      setState(() => _following = on);
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  bool get _isMe => _auth.currentUser?.id == widget.userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const LoadingView());
    }
    if (_error != null || _user == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'Error', onRetry: _load),
      );
    }

    final u = _user!;
    final totalViews = _stories.fold<int>(0, (s, e) => s + e.viewCount) +
        _novels.fold<int>(0, (s, e) => s + e.viewCount);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
          ),
        ],
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              child: Column(
                children: [
                  CachedAvatar(
                    userId: u.id,
                    imageUrl: u.avatarUrl,
                    name: u.displayName,
                    radius: 44,
                    tappable: false,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    u.displayNameOr(l10n.user),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (u.hasNickname) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${u.displayNickname}"',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (u.bio != null && u.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      u.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('${u.followerCount}', l10n.followers),
                      _stat('${u.followingCount}', l10n.following),
                      _stat(
                        TimeAgo.compactOf(context, totalViews),
                        l10n.views,
                      ),
                    ],
                  ),
                  if (!_isMe) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: _following
                          ? OutlinedButton.icon(
                              onPressed: _busy ? null : _toggleFollow,
                              icon: const Icon(Icons.person_remove),
                              label: Text(l10n.unfollow),
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _busy ? null : _toggleFollow,
                              icon: const Icon(Icons.person_add),
                              label: Text(l10n.follow),
                            ),
                    ),
                  ],
                ],
              ),
            ),
            TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: '${l10n.story} (${_stories.length})'),
                Tab(text: '${l10n.novel} (${_novels.length})'),
              ],
            ),
            SizedBox(
              height: 600,
              child: TabBarView(
                controller: _tab,
                children: [
                  _stories.isEmpty
                      ? Center(child: Text(l10n.noStoriesYet))
                      : ListView.builder(
                          itemCount: _stories.length,
                          itemBuilder: (_, i) => StoryCard(
                            story: _stories[i],
                            onTap: () => context.push(
                              '${RouteNames.story}/${_stories[i].id}',
                            ),
                          ),
                        ),
                  _novels.isEmpty
                      ? Center(child: Text(l10n.noNovelsYet))
                      : ListView.builder(
                          itemCount: _novels.length,
                          itemBuilder: (_, i) => NovelCard(
                            novel: _novels[i],
                            onTap: () => context.push(
                              '${RouteNames.novel}/${_novels[i].id}',
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: secondary),
        ),
      ],
    );
  }
}
