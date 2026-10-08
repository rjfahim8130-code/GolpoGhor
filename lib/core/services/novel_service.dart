import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';

class MyWorksScreen extends StatefulWidget {
  const MyWorksScreen({super.key});

  @override
  State<MyWorksScreen> createState() => _MyWorksScreenState();
}

class _MyWorksScreenState extends State<MyWorksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _storyService = StoryService();
  final _novelService = NovelService();

  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  bool _loading = true;

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
    setState(() => _loading = true);
    try {
      final stories = await _storyService.getMyStories(draftsOnly: false);
      final novels = await _novelService.getMyNovels();
      setState(() {
        _stories = stories.where((s) => !s.isDraft).toList();
        _novels = novels.where((n) => !n.isDraft).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDeleteStory(StoryModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('গল্প মুছবেন?'),
        content: Text(
          '"${s.title}" স্থায়ীভাবে মুছে যাবে। এটা ফেরানো যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _storyService.deleteStory(s.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('গল্প মুছে ফেলা হয়েছে')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('মুছা যায়নি: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteNovel(NovelModel n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('উপন্যাস মুছবেন?'),
        content: Text(
          '"${n.title}" এবং এর সব পর্ব মুছে যাবে। ফেরানো যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _novelService.deleteNovel(n.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('উপন্যাস মুছে ফেলা হয়েছে')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('মুছা যায়নি: $e')),
        );
      }
    }
  }

  void _showCreate() {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার লেখা'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          tabs: const [
            Tab(text: 'গল্প'),
            Tab(text: 'উপন্যাস'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _stories.isEmpty
                    ? const Center(child: Text('এখনো কোনো গল্প নেই'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _stories.length,
                          itemBuilder: (_, i) {
                            final s = _stories[i];
                            return ListTile(
                              title: Text(
                                s.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                s.isPublished ? 'প্রকাশিত' : 'খসড়া',
                              ),
                              onTap: () => context.push('/story/${s.id}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    context.push('/edit-story/${s.id}');
                                  }
                                  if (v == 'delete') {
                                    _confirmDeleteStory(s);
                                  }
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
                            );
                          },
                        ),
                      ),
                _novels.isEmpty
                    ? const Center(child: Text('এখনো কোনো উপন্যাস নেই'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _novels.length,
                          itemBuilder: (_, i) {
                            final n = _novels[i];
                            return ListTile(
                              title: Text(
                                n.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('${n.episodeCount} পর্ব'),
                              onTap: () => context.push('/novel/${n.id}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'open') {
                                    context.push('/novel/${n.id}');
                                  }
                                  if (v == 'edit') {
                                    context.push('/edit-novel/${n.id}');
                                  }
                                  if (v == 'delete') {
                                    _confirmDeleteNovel(n);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'open',
                                    child: Text('খুলুন'),
                                  ),
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
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}
