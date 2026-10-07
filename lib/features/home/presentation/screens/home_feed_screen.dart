import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/novel_card.dart';
import '../widgets/story_card.dart';

class HomeFeedScreen extends StatefulWidget {
  final bool embedded;

  const HomeFeedScreen({super.key, this.embedded = false});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _storyService = StoryService();
  final _novelService = NovelService();
  final _scroll = ScrollController();

  final List<dynamic> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  final int _limit = 15;

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
      final stories = await _storyService.getFeed(limit: _limit, offset: 0);
      final novels = await _novelService.getFeed(limit: 8, offset: 0);

      final combined = <dynamic>[...stories, ...novels];
      combined.sort((a, b) {
        final ad = a is StoryModel ? a.createdAt : (a as NovelModel).createdAt;
        final bd = b is StoryModel ? b.createdAt : (b as NovelModel).createdAt;
        return bd.compareTo(ad);
      });

      setState(() {
        _items
          ..clear()
          ..addAll(combined);
        _offset = stories.length;
        _hasMore = stories.length >= _limit;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'ফিড লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final more =
          await _storyService.getFeed(limit: _limit, offset: _offset);
      setState(() {
        _items.addAll(more);
        _offset += more.length;
        _hasMore = more.length >= _limit;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('নতুন গল্প'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/create-story');
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('নতুন উপন্যাস'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/create-novel');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'গল্পঘর',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'আবিষ্কার',
            onPressed: () => context.push('/discover'),
          ),
          IconButton(
            icon: const Icon(Icons.local_fire_department_outlined),
            tooltip: 'ট্রেন্ডিং',
            onPressed: () => context.push('/trending'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: body,
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
            ElevatedButton(onPressed: _load, child: const Text('আবার চেষ্টা')),
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/create-story'),
              child: const Text('প্রথম গল্প লিখুন'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 8, bottom: 88),
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
              onTap: () => context.push('/story/${item.id}'),
            );
          }
          if (item is NovelModel) {
            return NovelCard(
              novel: item,
              onTap: () => context.push('/novel/${item.id}'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
