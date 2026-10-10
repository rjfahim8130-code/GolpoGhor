import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../widgets/novel_card.dart';
import '../widgets/story_card.dart';

/// হোম ফিড
/// - সব বাটন উপরে
/// - নিচে ফাঁকা
/// - ভিডিও বাটন admin toggle-এর উপর নির্ভর
class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _storyService = StoryService();
  final _novelService = NovelService();
  final _scroll = ScrollController();

  final List<dynamic> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  static const int _limit = 15;

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
      final results = await Future.wait([
        _storyService.getFeed(limit: _limit, offset: 0),
        _novelService.getFeed(limit: 8, offset: 0),
      ]);

      final stories = results[0] as List<StoryModel>;
      final novels = results[1] as List<NovelModel>;

      final combined = <dynamic>[...stories, ...novels];
      combined.sort((a, b) {
        final ad = a is StoryModel ? a.createdAt : (a as NovelModel).createdAt;
        final bd = b is StoryModel ? b.createdAt : (b as NovelModel).createdAt;
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
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
        _error = 'ফিড লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _storyService.getFeed(limit: _limit, offset: _offset);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videoOn = ref.watch(videoFeatureProvider);
    final me = ref.watch(sessionCacheProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_watermark.png',
              height: 26,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'গল্পঘর',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline),
            tooltip: 'জনপ্রিয়',
            onPressed: () => context.push(RouteNames.popular),
          ),
          IconButton(
            icon: const Icon(Icons.local_fire_department_outlined),
            tooltip: 'ট্রেন্ডিং',
            onPressed: () => context.push(RouteNames.trending),
          ),
          if (videoOn)
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: 'ভিডিও',
              onPressed: () => context.push(RouteNames.videos),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(RouteNames.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RouteNames.search),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CachedAvatar(
              userId: me?.id,
              imageUrl: me?.avatarUrl,
              name: me?.displayName ?? 'আমি',
              radius: 16,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('আবার চেষ্টা'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text('এখনো কোনো গল্প নেই'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _items[index];
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
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
