// lib/features/home/presentation/screens/home_feed_screen.dart (Part 1)
// নতুন ডিজাইন হেডার (For you, popular, trending, following + Search)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/reading_history_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../routing/route_names.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/episode_card.dart';
import '../widgets/novel_card.dart';
import '../widgets/story_card.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

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
    return _items;
  }
  
