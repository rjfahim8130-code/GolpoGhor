import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../../../home/presentation/widgets/novel_card.dart';
import '../../../home/presentation/widgets/story_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _bookmarkService = BookmarkService();

  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  bool _loading = true;
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
      final stories = await _bookmarkService.getSavedStories();
      final novels = await _bookmarkService.getSavedNovels();
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _novels = novels;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সংরক্ষিত'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'গল্প'),
            Tab(text: 'উপন্যাস'),
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
                    _stories.isEmpty
                        ? const EmptyView(
                            icon: Icons.bookmark_outline,
                            title: 'কোনো সংরক্ষিত গল্প নেই',
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _stories.length,
                              itemBuilder: (_, i) {
                                final s = _stories[i];
                                return StoryCard(
                                  story: s,
                                  onTap: () => context.push(
                                    '${RouteNames.story}/${s.id}',
                                  ),
                                );
                              },
                            ),
                          ),
                    _novels.isEmpty
                        ? const EmptyView(
                            icon: Icons.bookmark_outline,
                            title: 'কোনো সংরক্ষিত উপন্যাস নেই',
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _novels.length,
                              itemBuilder: (_, i) {
                                final n = _novels[i];
                                return NovelCard(
                                  novel: n,
                                  onTap: () => context.push(
                                    '${RouteNames.novel}/${n.id}',
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
    );
  }
}
