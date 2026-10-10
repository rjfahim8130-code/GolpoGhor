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
        _novelService.getFeed(limit:
