import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/ui_strings.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../social/presentation/widgets/comment_section.dart';
import '../../../social/presentation/widgets/reaction_picker.dart';
import '../../../social/presentation/widgets/report_sheet.dart';
import '../../../story/presentation/widgets/reader_content.dart';
import '../../../story/presentation/widgets/reader_watermark.dart';

class EpisodeReaderScreen extends StatefulWidget {
  final String episodeId;

  const EpisodeReaderScreen({super.key, required this.episodeId});

  @override
  State<EpisodeReaderScreen> createState() => _EpisodeReaderScreenState();
}

class _EpisodeReaderScreenState extends State<EpisodeReaderScreen> {
  final _novelService = NovelService();
  final _offlineService = OfflineService();
  final _reactionService = ReactionService();
  final _scroll = ScrollController();

  EpisodeModel? _episode;
  String? _novelTitle;
  List<EpisodeModel> _siblings = [];
  bool _loading = true;
  String? _error;
  bool _downloaded = false;
  bool _downloading = false;
  String? _myReaction;
  Map<String, int> _reactionCounts = {};
  int _commentCount = 0;
  double _fontScale = 0.9;
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
    if (max <= 0) return;
    setState(() => _progress = (_scroll.offset / max).clamp(0.0, 1.0));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ep = await _novelService.getEpisodeById(widget.episodeId);
      if (ep == null) {
        setState(() {
          _error = 'পর্ব পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }
      final all = await _novelService.getEpisodes(ep.novelId);
      final novel = await _novelService.getById(ep.novelId);
      final dl = await _offlineService.isDownloaded('ep_${ep.id}');
      final myR = await _reactionService.getMyEpisodeReaction(ep.id);
      final counts = await _reactionService.countEpisodeReactions(ep.id);

      setState(() {
        _episode = ep;
        _siblings = all;
        _novelTitle = novel?.title;
        _downloaded = dl;
        _myReaction = myR;
        _reactionCounts = counts;
        _commentCount = ep.commentCount;
        _loading = false;
      });
      _novelService.recordView('episode', ep.id);
    } catch (_) {
      setState(() {
        _error = 'লোড সমস্যা';
        _loading = false;
      });
    }
  }

  EpisodeModel? get _prev {
    final ep = _episode;
    if (ep == null) return null;
    final i = _siblings.indexWhere((e) => e.id == ep.id);
    if (i > 0) return _siblings[i - 1];
    return null;
  }

  EpisodeModel? get _next {
    final ep = _episode;
    if (ep == null) return null;
    final i = _siblings.indexWhere((e) => e.id == ep.id);
    if (i >= 0 && i < _siblings.length - 1) return _siblings[i + 1];
    return null;
  }

  int get _totalReactions => _reactionCounts.values.fold(0, (a, b) => a + b);

  Future<void> _pickReaction() async {
    final type = await ReactionPicker.show(context);
    if (type == null) return;
    try {
      final result = await _reactionService.toggleEpisodeReaction(
        episodeId: widget.episodeId,
        reactionType: type,
      );
      final counts = await _reactionService.countEpisodeReactions(widget.episodeId);
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
          child: CommentSection(episodeId: widget.episodeId),
        );
      },
    ).then((_) async {
      try {
        final ep = await _novelService.getEpisodeById(widget.episodeId);
        if (ep != null && mounted) {
          setState(() => _commentCount = ep.commentCount);
        }
      } catch (_) {}
    });
  }

  Future<void> _download() async {
    final ep = _episode;
    if (ep == null) return;
    final offlineId = 'ep_${ep.id}';
    if (_downloaded) {
      await _offlineService.remove(offlineId);
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
      await _offlineService.saveStory(
        StoryModel(
          id: offlineId,
          authorId: ep.authorId,
          title: '${_novelTitle ?? ''} — ${ep.title}',
          description: 'পর্ব ${ep.chapterNumber}',
          contentBlocks: ep.contentBlocks,
          publicCode: ep.publicCode,
          isPublished: true,
          createdAt: ep.createdAt,
        ),
      );
      setState(() {
        _downloaded = true;
        _downloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(UiStrings.episodeSaved)),
        );
      }
    } catch (e) {
      setState(() => _downloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _share() async {
    final ep = _episode;
    if (ep == null) return;
    final code = ep.publicCode ?? '';
    await Share.share(
      '${_novelTitle ?? ''} — ${ep.title}\n'
      'পর্ব ${ep.chapterNumber}'
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
    if (_error != null || _episode == null) {
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
          child: Text(_error ?? 'সমস্যা', style: TextStyle(color: textPrimary)),
        ),
      );
    }

    final ep = _episode!;
    final prev = _prev;
    final next = _next;
    final titleText = '${_novelTitle ?? 'উপন্যাস'} · পর্ব ${ep.chapterNumber}';
    final reactionTotal = _totalReactions > 0 ? _totalReactions : ep.reactionCount;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
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
                        Expanded(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.flag_outlined, color: Colors.white),
                          tooltip: 'রিপোর্ট',
                          onPressed: () {
                            ReportSheet.show(
                              context,
                              targetType: 'episode',
                              targetId: widget.episodeId,
                              title: 'পর্ব রিপোর্ট',
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

          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: ReaderWatermark()),
                ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (ep.title.isNotEmpty) ...[
                      Text(
                        ep.title,
                        style: TextStyle(
                          fontSize: 20 * _fontScale,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SelectionContainer.disabled(
                      child: ReaderContent(
                        blocks: ep.contentBlocks,
                        fontScale: _fontScale,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _EpStat(
                          icon: Icons.remove_red_eye_outlined,
                          label: _fmtCount(ep.viewCount),
                          color: textSecondary,
                        ),
                        GestureDetector(
                          onTap: _pickReaction,
                          child: _EpStat(
                            icon: _myReaction != null ? Icons.favorite : Icons.favorite_border,
                            label: _fmtCount(reactionTotal),
                            color: _myReaction != null ? Colors.redAccent : textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openComments,
                          child: _EpStat(
                            icon: Icons.chat_bubble_outline,
                            label: _fmtCount(_commentCount),
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // বেগুনি বটম বার
          Material(
            color: AppColors.primary,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: prev == null ? Colors.white38 : Colors.white,
                      ),
                      tooltip: 'আগের পর্ব',
                      onPressed: prev == null ? null : () => context.pushReplacement('/episode/${prev.id}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields, color: Colors.white),
                      tooltip: UiStrings.fontSize,
                      onPressed: _showFontSheet,
                    ),
                    IconButton(
                      icon: _downloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _downloaded ? Icons.download_done : Icons.download_outlined,
                              color: Colors.white,
                            ),
                      tooltip: UiStrings.download,
                      onPressed: _downloading ? null : _download,
                    ),
                    IconButton(
                      icon: const Icon(Icons.list, color: Colors.white),
                      tooltip: 'পর্ব তালিকা',
                      onPressed: () => context.push('/novel/${ep.novelId}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white),
                      tooltip: UiStrings.share,
                      onPressed: _share,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: next == null ? Colors.white38 : Colors.white,
                      ),
                      tooltip: 'পরের পর্ব',
                      onPressed: next == null ? null : () => context.pushReplacement('/episode/${next.id}'),
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

class _EpStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _EpStat({
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
        Text(
          label,
          style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
