import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/story_model.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
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
  final _scroll = ScrollController();

  StoryModel? _story;
  bool _loading = true;
  String? _error;
  bool _bookmarked = false;
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
        setState(() {
          _error = 'গল্প পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }
      final bm = await _bookmarkService.isStoryBookmarked(widget.storyId);
      setState(() {
        _story = story;
        _bookmarked = bm;
        _loading = false;
      });
      // ভিউ কাউন্ট — ব্যাকগ্রাউন্ডে
      _storyService.recordView(widget.storyId);
    } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _share() async {
    final s = _story;
    if (s == null) return;
    final code = s.publicCode ?? '';
    final text = '${s.title}\n\n'
        'গল্পঘরে পড়ুন'
        '${code.isNotEmpty ? '\nকোড: $code' : ''}\n'
        '#গল্পঘর';
    await Share.share(text);
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
                    const SizedBox(height: 16),
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
                        Text(
                          '${(_fontScale * 100).round()}%',
                          style: const TextStyle(fontSize: 16),
                        ),
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
          // ওয়াটারমার্ক
          const Positioned.fill(child: ReaderWatermark()),
          // কনটেন্ট
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollUpdateNotification) {
                // স্ক্রলে কন্ট্রোল টগল করা ঐচ্ছিক — এখানে সবসময় দেখানো
              }
              return false;
            },
            child: CustomScrollView(
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
                          _bookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
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
                  const DiskSliverPadding(),
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
                                    color: AppColors.primary
                                        .withValues(alpha: 0.9),
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
                          const SizedBox(height: 20),
                          // কপি নিষেধ (হালকা অ্যান্টি-থেফট)
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
          ),
          // নিচের অ্যাকশন
          if (_showControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                elevation: 8,
                color: isDark ? AppColors.darkSurface : Colors.white,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BottomAction(
                          icon: Icons.favorite_border,
                          label: 'রিয়্যাকশন',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('রিয়্যাকশন পরের ব্যাচে'),
                              ),
                            );
                          },
                        ),
                        _BottomAction(
                          icon: Icons.chat_bubble_outline,
                          label: 'কমেন্ট',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('কমেন্ট পরের ব্যাচে'),
                              ),
                            );
                          },
                        ),
                        _BottomAction(
                          icon: Icons.download_outlined,
                          label: 'ডাউনলোড',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ডাউনলোড পরের ব্যাচে'),
                              ),
                            );
                          },
                        ),
                        _BottomAction(
                          icon: Icons.share_outlined,
                          label: 'শেয়ার',
                          onTap: _share,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DiskSliverPadding extends StatelessWidget {
  const DiskSliverPadding();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox(height: 48));
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
