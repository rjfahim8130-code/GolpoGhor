// lib/features/reader/presentation/screens/reader_screen.dart
// সংশোধিত: notification trigger, localization, ownerId reaction-এ

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';
import '../../../social/presentation/widgets/comment_section.dart';
import '../../../social/presentation/widgets/reaction_picker.dart';
import '../../../social/presentation/widgets/report_sheet.dart';
import '../widgets/reader_bottom_bar.dart';
import '../widgets/reader_content.dart';
import '../widgets/reader_watermark.dart';

enum ReaderKind { story, episode }

class ReaderScreen extends StatefulWidget {
  final ReaderKind kind;
  final String id;

  const ReaderScreen({
    super.key,
    required this.kind,
    required this.id,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _storyService = StoryService();
  final _episodeService = EpisodeService();
  final _novelService = NovelService();
  final _bookmarkService = BookmarkService();
  final _reactionService = ReactionService();
  final _offlineService = OfflineService();
  final _scroll = ScrollController();

  StoryModel? _story;
  EpisodeModel? _episode;
  String? _novelTitle;
  List<EpisodeModel> _siblings = [];

  bool _loading = true;
  String? _error;
  bool _bookmarked = false;
  bool _downloaded = false;
  bool _downloading = false;
  String? _myReaction;
  int _reactionTotal = 0;
  int _commentCount = 0;
  int _viewCount = 0;
  double _fontScale = AppConstants.defaultFontScale;
  double _progress = 0;

  bool get _isStory => widget.kind == ReaderKind.story;

  /// কমেন্ট ও reaction-এর জন্য পোস্টের মালিক
  String? get _ownerId {
    if (_isStory) return _story?.authorId;
    return _episode?.authorId;
  }

  EpisodeModel? get _prev {
    if (_isStory) return null;
    final ep = _episode;
    if (ep == null) return null;
    final i = _siblings.indexWhere((e) => e.id == ep.id);
    if (i > 0) return _siblings[i - 1];
    return null;
  }

  EpisodeModel? get _next {
    if (_isStory) return null;
    final ep = _episode;
    if (ep == null) return null;
    final i = _siblings.indexWhere((e) => e.id == ep.id);
    if (i >= 0 && i < _siblings.length - 1) return _siblings[i + 1];
    return null;
  }

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
      if (_isStory) {
        await _loadStory();
      } else {
        await _loadEpisode();
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      final offline = await _offlineService.get(widget.id);
      if (offline != null) {
        if (!mounted) return;
        setState(() {
          _story = offline.toStoryModel();
          _downloaded = true;
          _loading = false;
          _error = null;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = 'লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  Future<void> _loadStory() async {
    final story = await _storyService.getById(widget.id);
    if (story == null) {
      final offline = await _offlineService.get(widget.id);
      if (offline != null) {
        if (!mounted) return;
        setState(() {
          _story = offline.toStoryModel();
          _downloaded = true;
        });
        return;
      }
      throw Exception('পাওয়া যায়নি');
    }

    final bm = await _bookmarkService.isStoryBookmarked(widget.id);
    final myR = await _reactionService.getMyStoryReaction(widget.id);
    final counts = await _reactionService.countStoryReactions(widget.id);
    final dl = await _offlineService.isDownloaded(widget.id);

    if (!mounted) return;
    setState(() {
      _story = story;
      _bookmarked = bm;
      _myReaction = myR;
      _reactionTotal = counts.values.fold(0, (a, b) => a + b);
      _commentCount = story.commentCount;
      _viewCount = story.viewCount;
      _downloaded = dl;
    });

    _storyService.recordView(widget.id);
  }

  Future<void> _loadEpisode() async {
    final ep = await _episodeService.getById(widget.id);
    if (ep == null) {
      final offline = await _offlineService.get('ep_${widget.id}');
      if (offline != null) {
        if (!mounted) return;
        setState(() {
          _story = offline.toStoryModel();
          _novelTitle = offline.subtitle;
          _downloaded = true;
        });
        return;
      }
      throw Exception('পাওয়া যায়নি');
    }

    final siblings = await _episodeService.getByNovel(ep.novelId);
    final novel = await _novelService.getById(ep.novelId);
    final myR = await _reactionService.getMyEpisodeReaction(ep.id);
    final counts = await _reactionService.countEpisodeReactions(ep.id);
    final dl = await _offlineService.isDownloaded('ep_${ep.id}');

    if (!mounted) return;
    setState(() {
      _episode = ep;
      _siblings = siblings;
      _novelTitle = novel?.title;
      _myReaction = myR;
      _reactionTotal = counts.values.fold(0, (a, b) => a + b);
      _commentCount = ep.commentCount;
      _viewCount = ep.viewCount;
      _downloaded = dl;
    });

    _episodeService.recordView(ep.id);
  }
  
  Future<void> _toggleBookmark() async {
    try {
      if (_isStory) {
        final on = await _bookmarkService.toggleStoryBookmark(widget.id);
        if (!mounted) return;
        setState(() => _bookmarked = on);
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(on ? l10n.bookmark : l10n.bookmark),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _download() async {
    if (_downloaded) {
      await _offlineService.remove(_isStory ? widget.id : 'ep_${widget.id}');
      if (!mounted) return;
      setState(() => _downloaded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ডাউনলোড সরানো হয়েছে')),
      );
      return;
    }

    setState(() => _downloading = true);
    try {
      if (_isStory) {
        final s = _story;
        if (s == null) return;
        await _offlineService.saveStory(s);
      } else {
        final ep = _episode;
        if (ep == null) return;
        await _offlineService.saveEpisode(
          episodeId: ep.id,
          novelTitle: _novelTitle ?? '',
          episodeTitle: ep.title,
          chapterNumber: ep.chapterNumber,
          contentBlocks: ep.contentBlocks,
          authorName: _story?.authorName,
          publicCode: ep.publicCode,
        );
      }
      if (!mounted) return;
      setState(() {
        _downloaded = true;
        _downloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অফলাইনে ডাউনলোড হয়েছে')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _pickReaction() async {
    final type = await ReactionPicker.show(context);
    if (type == null) return;
    try {
      String? result;
      int total;
      if (_isStory) {
        result = await _reactionService.toggleStoryReaction(
          storyId: widget.id,
          reactionType: type,
          ownerId: _ownerId,
        );
        final counts =
            await _reactionService.countStoryReactions(widget.id);
        total = counts.values.fold(0, (a, b) => a + b);
      } else {
        result = await _reactionService.toggleEpisodeReaction(
          episodeId: widget.id,
          reactionType: type,
          ownerId: _ownerId,
        );
        final counts =
            await _reactionService.countEpisodeReactions(widget.id);
        total = counts.values.fold(0, (a, b) => a + b);
      }
      if (!mounted) return;
      setState(() {
        _myReaction = result;
        _reactionTotal = total;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
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
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: _isStory
            ? CommentSection(
                storyId: widget.id,
                ownerId: _ownerId,
              )
            : CommentSection(
                episodeId: widget.id,
                ownerId: _ownerId,
              ),
      ),
    ).then((_) async {
      try {
        if (_isStory) {
          final s = await _storyService.getById(widget.id);
          if (s != null && mounted) {
            setState(() => _commentCount = s.commentCount);
          }
        } else {
          final ep = await _episodeService.getById(widget.id);
          if (ep != null && mounted) {
            setState(() => _commentCount = ep.commentCount);
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _share() async {
    final code = _isStory ? _story?.publicCode : _episode?.publicCode;
    final title = _isStory
        ? (_story?.title ?? '')
        : '${_novelTitle ?? ''} — ${_episode?.title ?? ''}';
    await Share.share(
      '$title\nগল্পঘরে পড়ুন'
      '${code != null && code.isNotEmpty ? '\nকোড: $code' : ''}\n#গল্পঘর',
    );
  }

  void _showFontSheet() {
    final l10n = context.l10n;
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
                    Text(
                      l10n.fontSize,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale -
                                      AppConstants.fontScaleStep)
                                  .clamp(
                                AppConstants.minFontScale,
                                AppConstants.maxFontScale,
                              );
                            });
                            setModal(() {});
                          },
                          icon: const Icon(Icons.text_decrease),
                        ),
                        Text('${(_fontScale * 100).round()}%'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale +
                                      AppConstants.fontScaleStep)
                                  .clamp(
                                AppConstants.minFontScale,
                                AppConstants.maxFontScale,
                              );
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
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _story == null) {
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
              Text(_error!, style: TextStyle(color: textPrimary)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('আবার')),
            ],
          ),
        ),
      );
    }

    final title = _isStory
        ? (_story?.title ?? '')
        : (_episode?.title.isNotEmpty == true
            ? _episode!.title
            : 'পর্ব ${_episode?.chapterNumber ?? 1}');
    final authorName = _story?.authorName;
    final authorId = _isStory ? _story?.authorId : _episode?.authorId;
    final authorAvatar = _story?.authorAvatar;
    final description = _isStory ? (_story?.description ?? '') : '';
    final publicCode =
        _isStory ? _story?.publicCode : _episode?.publicCode;
    final contentBlocks = _isStory
        ? (_story?.contentBlocks ?? [])
        : (_episode?.contentBlocks ?? []);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // সবুজ টপ বার
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
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            _isStory
                                ? l10n.story
                                : '${_novelTitle ?? l10n.novel} · ${l10n.episode} ${_episode?.chapterNumber ?? 1}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.flag_outlined,
                              color: Colors.white),
                          onPressed: () {
                            ReportSheet.show(
                              context,
                              targetType: _isStory ? 'story' : 'episode',
                              targetId: widget.id,
                              title: _isStory ? 'গল্প রিপোর্ট' : 'পর্ব রিপোর্ট',
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
                    if (authorId != null && authorId.isNotEmpty) ...[
                      Center(
                        child: Column(
                          children: [
                            CachedAvatar(
                              userId: authorId,
                              imageUrl: authorAvatar,
                              name: authorName ?? 'লেখক',
                              radius: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              authorName ?? 'লেখক',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 22 * _fontScale,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (publicCode != null && publicCode.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyCode(publicCode),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                publicCode,
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

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14 * _fontScale,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
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
                        blocks: contentBlocks,
                        fontScale: _fontScale,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat(
                          Icons.remove_red_eye_outlined,
                          TimeAgo.compact(_viewCount),
                          textSecondary,
                        ),
                        GestureDetector(
                          onTap: _pickReaction,
                          child: _stat(
                            _myReaction != null
                                ? Icons.favorite
                                : Icons.favorite_border,
                            TimeAgo.compact(_reactionTotal),
                            _myReaction != null
                                ? Colors.redAccent
                                : textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openComments,
                          child: _stat(
                            Icons.chat_bubble_outline,
                            TimeAgo.compact(_commentCount),
                            textSecondary,
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

          ReaderBottomBar(
            items: [
              ReaderBottomBarItem(
                icon: _downloaded
                    ? Icons.download_done
                    : Icons.download_outlined,
                label: l10n.download,
                loading: _downloading,
                onTap: _downloading ? null : _download,
              ),
              ReaderBottomBarItem(
                icon: Icons.text_fields,
                label: l10n.fontSize,
                onTap: _showFontSheet,
              ),
              if (_isStory)
                ReaderBottomBarItem(
                  icon: _bookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  label: l10n.bookmark,
                  active: _bookmarked,
                  onTap: _toggleBookmark,
                ),
              ReaderBottomBarItem(
                icon: Icons.share_outlined,
                label: l10n.share,
                onTap: _share,
              ),
              if (!_isStory)
                ReaderBottomBarItem(
                  icon: Icons.chevron_left,
                  label: l10n.prevEpisode,
                  onTap: _prev == null
                      ? null
                      : () => context.pushReplacement(
                            '${RouteNames.episode}/${_prev!.id}',
                          ),
                ),
              if (!_isStory)
                ReaderBottomBarItem(
                  icon: Icons.chevron_right,
                  label: l10n.nextEpisode,
                  onTap: _next == null
                      ? null
                      : () => context.pushReplacement(
                            '${RouteNames.episode}/${_next!.id}',
                          ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
