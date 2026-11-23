// lib/features/home/presentation/screens/home_feed_screen.dart
// নতুন ডিজাইন হেডার (For you, popular, trending, following + Search)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/reading_history_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../routing/route_names.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/episode_card.dart';
import '../widgets/novel_card.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/story_card.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _storyService = StoryService();
  final _novelService = NovelService();
  final _episodeService = EpisodeService();
  final _historyService = ReadingHistoryService();
  final _scroll = ScrollController();

  final List<dynamic> _items = [];
  final List<ReadingHistoryItem> _history = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  static const int _limit = 15;
  int _selectedTab = 0; // 0: For You, 1: Popular, 2: Trending, 3: Following

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });
    try {
      final history = await _historyService.getAll();
      final results = await Future.wait([
        _storyService.getFeed(limit: _limit, offset: 0),
        _novelService.getFeed(limit: 8, offset: 0),
        _episodeService.getFeed(limit: 10, offset: 0),
      ]);

      final stories = results[0] as List<StoryModel>;
      final novels = results[1] as List<NovelModel>;
      final episodes = results[2] as List<EpisodeModel>;

      final combined = <dynamic>[...stories, ...novels, ...episodes];
      combined.sort((a, b) {
        final DateTime ad = _getCreatedAt(a);
        final DateTime bd = _getCreatedAt(b);
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
        _history.clear();
        _history.addAll(history.take(3));
        _items
          ..clear()
          ..addAll(combined);
        _offset = stories.length;
        _hasMore = stories.length >= _limit;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'loadFailed';
        _loading = false;
      });
    }
  }

  DateTime _getCreatedAt(dynamic item) {
    if (item is StoryModel) return item.createdAt;
    if (item is NovelModel) return item.createdAt;
    if (item is EpisodeModel) return item.createdAt;
    return DateTime.now();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _storyService.getFeed(
        limit: _limit,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(more);
        _offset += more.length;
        _hasMore = more.length >= _limit;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<dynamic> get _filteredItems {
    // ফিল্টারিং লজিক আপনার প্রয়োজনমতো অ্যাডজাস্ট করতে পারেন
    return _items;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // নতুন ডিজাইন অনুযায়ী ৪টি ট্যাব: For You, Popular, Trending, Following
    final tabs = ['For You', 'Popular', 'Trending', 'Following'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      // ✅ নতুন ট্রান্সপারেন্ট হেডার (লোগো/নাম ছাড়া, শুধু ফিল্টার ও সার্চ)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 44,
        titleSpacing: 8,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.4,
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        title: Row(
          children: [
            for (var index = 0; index < tabs.length; index++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selectedTab = index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      tabs[index],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedTab == index
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white54 : Colors.black54),
                        fontWeight: _selectedTab == index
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              size: 22,
              color: isDark ? Colors.white : Colors.black,
            ),
            tooltip: 'Search stories',
            onPressed: () => context.push(RouteNames.search),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
      body: _buildBody(context.l10n, tabs),
    );
  }

  Widget _buildBody(AppLocalizations l10n, List<String> tabs) {
    if (_loading) {
      return const SkeletonList(count: 3);
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.t(_error!)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredItems;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: (filtered.isEmpty && _selectedTab == 0)
            ? 2
            : (_selectedTab == 0 && _history.isNotEmpty
                    ? 1
                    : 0) +
                filtered.length +
                (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          int adjustedIndex = index;

          if (_selectedTab == 0 && _history.isNotEmpty) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.recent,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(RouteNames.history),
                          child: Text(
                            l10n.seeMore,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._history.map(
                    (h) => ContinueReadingCard(item: h),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }
            adjustedIndex = index - 1;
          }

          if (adjustedIndex >= filtered.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = filtered[adjustedIndex];
          if (item is StoryModel) {
            return StoryCard(
              story: item,
              onTap: () => context.push('${RouteNames.story}/${item.id}'),
            );
          }
          if (item is NovelModel) {
            return NovelCard(
              novel: item,
              onTap: () => context.push('${RouteNames.novel}/${item.id}'),
            );
          }
          if (item is EpisodeModel) {
            return EpisodeCard(
              episode: item,
              onTap: () => context.push(
                '${RouteNames.episode}/${item.id}',
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
