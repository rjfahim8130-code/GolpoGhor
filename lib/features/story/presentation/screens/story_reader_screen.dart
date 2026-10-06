import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/story_model.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../social/presentation/widgets/comment_section.dart';
import '../../../social/presentation/widgets/reaction_picker.dart';
import '../widgets/reader_content.dart';
import '../widgets/reader_watermark.dart';

class StoryReaderScreen extends StatefulWidget {
  final String storyId;

  const StoryReaderScreen({super.key, required this.storyId});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  final _storyService = StoryService();
  final _bookmarkService = BookmarkService();
  final _reactionService = ReactionService();
  final _offlineService = OfflineService();
  final _scroll = ScrollController();

  StoryModel? _story;
  bool _loading = true;
  String? _error;
  bool _bookmarked = false;
  bool _downloaded = false;
  bool _downloading = false;
  String? _myReaction;
  Map<String, int> _reactionCounts = {};
  double _fontScale = 1.0;
  bool _showControls = true;
  double _progress = 0;

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
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) {
      setState(() => _progress = 0);
      return;
    }
    setState(() {
      _progress = (_scroll.offset / max).clamp(0.0, 1.0);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final story = await _storyService.getById(widget.storyId);
      if (story == null) {
        final offline = await _offlineService.getStory(widget.storyId);
        if (offline != null) {
          setState(() {
            _story = offline.toStoryModel();
            _downloaded = true;
            _loading = false;
          });
          return;
        }
        setState(() {
          _error = 'গল্প পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }
      final bm = await _bookmarkService.isStoryBookmarked(widget.storyId);
      final myR =
          await _reactionService.getMyStoryReaction(widget.storyId);
      final counts =
          await _reactionService.countStoryReactions(widget.storyId);
      final dl = await _offlineService.isDownloaded(widget.storyId);
      setState(() {
        _story = story;
        _bookmarked = bm;
        _myReaction = myR;
        _reactionCounts = counts;
        _downloaded = dl;
        _loading = false;
      });
      _storyService.recordView(widget.storyId);
    } catch (e) {
      final offline = await _offlineService.getStory(widget.storyId);
      if (offline != null) {
        setState(() {
          _story = offline.toStoryModel();
          _downloaded = true;
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _error = 'লোড সমস্যা';
        _loading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final on = await _bookmarkService.toggleStoryBookmark(widget.storyId);
      setState(() => _bookmarked = on);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(on ? 'সংরক্ষিত হয়েছে' : 'সংরক্ষণ সরানো হয়েছে'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _download() async {
    final story = _story;
    if (story == null) return;
    if (_downloaded) {
      await _offlineService.remove(story.id);
      setState(() => _downloaded = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ডাউনলোড সরানো হয়েছে')),
        );
      }
      return;
    }
    setState(() => _downloading = true);
    try {
      await _offlineService.saveStory(story);
      setState(() {
        _downloaded = true;
        _downloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অফলাইনে সেভ হয়েছে')),
        );
      }
    } catch (e) {
      setState(() => _downloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _pickReaction() async {
    final type = await ReactionPicker.show(context);
    if (type == null) return;
    try {
      final result = await _reactionService.toggleStoryReaction(
        storyId: widget.storyId,
        reactionType: type,
      );
      final counts =
          await _reactionService.countStoryReactions(widget.storyId);
      setState(() {
        _myReaction = result;
        _reactionCounts = counts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: CommentSection(storyId: widget.storyId),
        );
      },
    ).then((_) => _load());
  }

  Future<void> _share() async {
    final s = _story;
    if (s == null) return;
    final code = s.publicCode ?? '';
    await Share.share(
      '${s.title}\n\nগল্পঘরে পড়ুন'
      '${code.isNotEmpty ? '\nকোড: $code' : ''}\n#গল্পঘর',
    );
  }

  void _showFontSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ফন্ট সাইজ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale - 0.1).clamp(0.8, 1.6);
                            });
                            setModal(() {});
                          },
                          icon: const Icon(Icons.text_decrease),
                        ),
                        Text('${(_fontScale * 100).round()}%'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale + 0.1).clamp(0.8, 1.6);
                            });
                            setModal(() {});
                          },
                          icon: const Icon(Icons.text_increase),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int get _totalReactions =>
      _reactionCounts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _story == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'সমস্যা'),
              TextButton(onPressed: _load, child: const Text('আবার')),
            ],
          ),
        ),
      );
    }

    final story = _story!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ReaderWatermark()),
          CustomScrollView(
            controller: _scroll,
            slivers: [
              if (_showControls)
                SliverAppBar(
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  title: Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.text_fields),
                      onPressed: _showFontSheet,
                    ),
                    IconButton(
                      icon: Icon(
                        _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: _bookmarked ? AppColors.primary : null,
                      ),
                      onPressed: _toggleBookmark,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: _share,
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(3),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 3,
                      backgroundColor: Colors.transparent,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (!_showControls)
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => setState(() => _showControls = !_showControls),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: TextStyle(
                            fontSize: 24 * _fontScale,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              story.authorName ?? 'লেখক',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            if (story.publicCode != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '· ${story.publicCode}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '${story.viewCount} দেখা',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (_totalReactions > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            _reactionCounts.entries
                                .map((e) =>
                                    '${ReactionPicker.emoji(e.key)} ${e.value}')
                                .join('  '),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SelectionContainer.disabled(
                          child: ReaderContent(
                            blocks: story.contentBlocks,
                            fontScale: _fontScale,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'গল্পঘর থেকে পঠিত',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
