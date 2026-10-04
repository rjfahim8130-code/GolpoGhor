import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/story_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final _storyService = StoryService();
  List<StoryModel> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _storyService.getMyStories(draftsOnly: true);
      setState(() {
        _drafts = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _publish(StoryModel s) async {
    try {
      await _storyService.updateStory(
        storyId: s.id,
        isDraft: false,
        isPublished: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('প্রকাশিত হয়েছে')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _delete(StoryModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('খসড়া মুছবেন?'),
        content: Text('"${s.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _storyService.deleteStory(s.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('খসড়া'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/create-story'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.drafts_outlined,
                        size: 64,
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text('কোনো খসড়া নেই'),
                      TextButton(
                        onPressed: () => context.push('/create-story'),
                        child: const Text('নতুন গল্প'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _drafts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = _drafts[i];
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
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'publish') _publish(s);
                            if (v == 'edit') {
                              context.push('/edit-story/${s.id}');
                            }
                            if (v == 'delete') _delete(s);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'publish',
                              child: Text('প্রকাশ করুন'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('এডিট'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('মুছুন'),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/edit-story/${s.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
