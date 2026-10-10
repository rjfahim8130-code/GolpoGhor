import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';

class DraftListScreen extends StatefulWidget {
  const DraftListScreen({super.key});

  @override
  State<DraftListScreen> createState() => _DraftListScreenState();
}

class _DraftListScreenState extends State<DraftListScreen> {
  final _storyService = StoryService();
  final _novelService = NovelService();

  List<StoryModel> _storyDrafts = [];
  List<NovelModel> _novelDrafts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _storyService.getMyStories(draftsOnly: true);
      final allNovels = await _novelService.getMyNovels();
      final nd = allNovels.where((n) => n.isDraft).toList();

      if (!mounted) return;
      setState(() {
        _storyDrafts = s;
        _novelDrafts = nd;
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

  Future<void> _deleteStory(StoryModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('খসড়া মুছবেন?'),
        content: Text(s.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _storyService.deleteStory(s.id);
    await _load();
  }

  Future<void> _deleteNovel(NovelModel n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('খসড়া মুছবেন?'),
        content: Text(n.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _novelService.deleteNovel(n.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final empty = _storyDrafts.isEmpty && _novelDrafts.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('খসড়া'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : empty
                  ? const EmptyView(
                      icon: Icons.drafts_outlined,
                      title: 'কোনো খসড়া নেই',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          if (_storyDrafts.isNotEmpty) ...[
                            _sectionTitle('গল্প', secondary),
                            ..._storyDrafts.map((s) {
                              return ListTile(
                                title: Text(
                                  s.title.isEmpty ? '(শিরোনামহীন)' : s.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  s.updatedAt != null
                                      ? 'আপডেট: ${s.updatedAt!.day}/${s.updatedAt!.month}/${s.updatedAt!.year}'
                                      : '',
                                  style: TextStyle(color: secondary),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') {
                                      context.push(
                                        '${RouteNames.writeStory}/${s.id}',
                                      );
                                    }
                                    if (v == 'delete') _deleteStory(s);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('সম্পাদনা'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'মুছুন',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => context.push(
                                  '${RouteNames.writeStory}/${s.id}',
                                ),
                              );
                            }),
                          ],
                          if (_novelDrafts.isNotEmpty) ...[
                            _sectionTitle('উপন্যাস', secondary),
                            ..._novelDrafts.map((n) {
                              return ListTile(
                                title: Text(
                                  n.title.isEmpty ? '(শিরোনামহীন)' : n.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  n.updatedAt != null
                                      ? 'আপডেট: ${n.updatedAt!.day}/${n.updatedAt!.month}/${n.updatedAt!.year}'
                                      : '',
                                  style: TextStyle(color: secondary),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') {
                                      context.push(
                                        '${RouteNames.writeNovel}/${n.id}',
                                      );
                                    }
                                    if (v == 'delete') _deleteNovel(n);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('সম্পাদনা'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'মুছুন',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => context.push(
                                  '${RouteNames.writeNovel}/${n.id}',
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _sectionTitle(String text, Color secondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
      ),
    );
  }
}
