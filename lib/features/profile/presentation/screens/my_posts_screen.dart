// lib/features/profile/presentation/screens/my_posts_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/video_model.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../widgets/profile_posts_tab.dart';

class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({super.key});

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

  final _storyService = StoryService();
  final _novelService = NovelService();
  final _videoService = VideoService();

  late TabController _tab;
  bool _loading = true;
  String? _error;
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
      final videoOn = ref.read(videoFeatureProvider);
      final stories = await _storyService.getMyStories(draftsOnly: false);
      final novels = await _novelService.getMyNovels();
      final videos =
          videoOn ? await _videoService.getMyVideos() : <VideoModel>[];

      if (!mounted) return;
      setState(() {
        _videoOn = videoOn;
        _stories = stories.where((s) => !s.isDraft).toList();
        _novels = novels.where((n) => !n.isDraft).toList();
        _videos = videos;
        _loading = false;
      });

      final desiredLength = videoOn ? 3 : 2;
      if (_tab.length != desiredLength) {
        final currentIndex = _tab.index.clamp(0, desiredLength - 1);
        _tab.dispose();
        _tab = TabController(
          length: desiredLength,
          vsync: this,
          initialIndex: currentIndex,
        );
        if (mounted) setState(() {});
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.loadFailed;
        _loading = false;
      });
    }
  }

  Future<void> _deleteStory(StoryModel s) async {
    final l10n = context.l10n;
    final ok = await _confirm(l10n.deleteStoryConfirm, s.title);
    if (ok != true) return;
    await _storyService.deleteStory(s.id);
    await _load();
  }

  Future<void> _deleteNovel(NovelModel n) async {
    final l10n = context.l10n;
    final ok = await _confirm(
      l10n.deleteNovelConfirm,
      '${n.title} ${l10n.deleteNovelConfirmBody}',
    );
    if (ok != true) return;
    await _novelService.deleteNovel(n.id);
    await _load();
  }

  Future<void> _deleteVideo(VideoModel v) async {
    final l10n = context.l10n;
    final ok = await _confirm(l10n.deleteVideoConfirm, l10n.cannotUndo);
    if (ok != true) return;
    await _videoService.deleteVideo(v.id);
    await _load();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final tabCount = _videoOn ? 3 : 2;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.myWorks),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: _loading
            ? null
            : TabBar(
                controller: _tab,
                labelColor: _brandGreen,
                unselectedLabelColor: secondary,
                indicatorColor: _brandGreen,
                tabs: [
                  Tab(text: l10n.story),
                  Tab(text: l10n.novel),
                  if (_videoOn) Tab(text: l10n.video),
                ],
              ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tab,
                  children: [
                    ProfilePostsTab.stories(
                      stories: _stories,
                      onOpenStory: (s) =>
                          context.push('${RouteNames.story}/${s.id}'),
                      onEditStory: (s) => context.push(
                        '${RouteNames.writeStory}/${s.id}',
                      ),
                      onDeleteStory: _deleteStory,
                    ),
                    ProfilePostsTab.novels(
                      novels: _novels,
                      onOpenNovel: (n) =>
                          context.push('${RouteNames.novel}/${n.id}'),
                      onEditNovel: (n) => context.push(
                        '${RouteNames.writeNovel}/${n.id}',
                      ),
                      onDeleteNovel: _deleteNovel,
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
                        onEditVideo: (v) => context.push(
                          '${RouteNames.createVideo}/${v.id}',
                        ),
                        onDeleteVideo: _deleteVideo,
                      ),
                  ].take(tabCount).toList(),
                ),
    );
  }
}
