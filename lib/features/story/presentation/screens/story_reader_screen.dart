import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/ui_strings.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../social/presentation/widgets/comment_section.dart';
import '../../../social/presentation/widgets/reaction_picker.dart';
import '../../../social/presentation/widgets/report_sheet.dart';
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
  double _fontScale = 0.95;
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
    setState(() => _progress = (_scroll.offset / max).clamp(0.0, 1.0));
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
      final myR = await _reactionService.getMyStoryReaction(widget.storyId);
      final counts = await _reactionService.countStoryReactions(widget.storyId);
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
            content: Text(on ? UiStrings.bookmarkOn : UiStrings.bookmarkOff),
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
          const SnackBar(content: Text(UiStrings.downloadRemoved)),
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
          const SnackBar(content: Text(UiStrings.downloadSaved)),
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
      final counts = await _reactionService.countStoryReactions(widget.storyId);
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
                      UiStrings.fontSize,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale - 0.08).clamp(0.55, 1.5);
                            });
                            setModal(() {});
                          },
                          icon: const Icon(Icons.text_decrease),
                        ),
                        Text('${(_fontScale * 100).round()}%'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale + 0.08).clamp(0.55, 1.5);
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

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('কোড কপি হয়েছে')),
    );
  }

  int get _totalReactions => _reactionCounts.values.fold(0, (a, b) => a + b);

  String _fmtCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} হাজার';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _story == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'সমস্যা', style: TextStyle(color: textPrimary)),
              TextButton(onPressed: _load, child: const Text('আবার')),
            ],
          ),
        ),
      );
    }

    final story = _story!;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ফিক্সড বেগুনি টপ (রিপোর্ট বাটনসহ)
          Material(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.flag_outlined, color: Colors.white),
                          tooltip: 'রিপোর্ট',
                          onPressed: () {
                            ReportSheet.show(
                              context,
                              targetType: 'story',
                              targetId: widget.storyId,
                              title: 'গল্প রিপোর্ট',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 2,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // মাঝ — থিম অনুযায়ী + ওয়াটারমার্ক
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: ReaderWatermark()),
                ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          if (story.authorId.isNotEmpty) {
                            context.push('/user/${story.authorId}');
                          }
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              backgroundImage: story.authorAvatar != null && story.authorAvatar!.isNotEmpty
                                  ? CachedNetworkImageProvider(story.authorAvatar!)
                                  : null,
                              child: story.authorAvatar == null || story.authorAvatar!.isEmpty
                                  ? Text(
                                      (story.authorName ?? 'ল')[0],
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              story.authorName ?? 'লেখক',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            story.title,
                            style: TextStyle(
                              fontSize: 24 * _fontScale,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (story.publicCode != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyCode(story.publicCode!),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                story.publicCode!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (story.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        story.description,
                        style: TextStyle(
                          fontSize: 14 * _fontScale,
                          color: textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectionContainer.disabled(
                      child: ReaderContent(
                        blocks: story.contentBlocks,
                        fontScale: _fontScale,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatChip(
                          icon: Icons.remove_red_eye_outlined,
                          label: _fmtCount(story.viewCount),
                          color: textSecondary,
                        ),
                        GestureDetector(
                          onTap: _pickReaction,
                          child: _StatChip(
                            icon: _myReaction != null ? Icons.favorite : Icons.favorite_border,
                            label: _fmtCount(
                              _totalReactions > 0 ? _totalReactions : story.reactionCount,
                            ),
                            color: _myReaction != null ? Colors.redAccent : textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openComments,
                          child: _StatChip(
                            icon: Icons.chat_bubble_outline,
                            label: _fmtCount(story.commentCount),
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
          
          // ফিক্সড বেগুনি বটম
          Material(
            color: AppColors.primary,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PurpleBarBtn(
                      icon: _downloading ? null : (_downloaded ? Icons.download_done : Icons.download_outlined),
                      label: UiStrings.download,
                      onTap: _downloading ? null : _download,
                      loading: _downloading,
                    ),
                    _PurpleBarBtn(
                      icon: Icons.text_fields,
                      label: UiStrings.fontSize,
                      onTap: _showFontSheet,
                    ),
                    _PurpleBarBtn(
                      icon: _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      label: UiStrings.bookmark,
                      onTap: _toggleBookmark,
                    ),
                    _PurpleBarBtn(
                      icon: Icons.share_outlined,
                      label: UiStrings.share,
                      onTap: _share,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.lightTextSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PurpleBarBtn extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PurpleBarBtn({
    this.icon,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon ?? Icons.circle, size: 22, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
