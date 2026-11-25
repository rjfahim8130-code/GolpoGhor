// lib/features/reader/presentation/screens/reader_screen.dart (Part 1)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/reading_history_service.dart';
import '../../../../core/services/story_service.dart';
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

enum ReaderTheme { light, sepia, dark }

double _globalFontScale = AppConstants.defaultFontScale;
ReaderTheme _globalReaderTheme = ReaderTheme.light;

class ReaderScreen extends StatefulWidget {
  final ReaderKind kind;
  final String id;

  const ReaderScreen({super.key, required this.kind, required this.id});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  static const Color _barGreen = Color(0xFF159447);

  final _follow = FollowService();
  bool _isFollowingAuthor = false;
  bool _followBusy = false;
  int _authorFollowerCount = 0;

  final _storyService = StoryService();
  final _episodeService = EpisodeService();
  final _novelService = NovelService();
  final _bookmarkService = BookmarkService();
  final _reactionService = ReactionService();
  final _offlineService = OfflineService();
  final _historyService = ReadingHistoryService();
  final _scroll = ScrollController();

  StoryModel? _story;
  EpisodeModel? _episode;
  String? _novelTitle;
  String? _authorName;
  String? _authorAvatar;
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
  double _progress = 0;

  bool get _isStory => widget.kind == ReaderKind.story;

  String? get _ownerId => _isStory ? _story?.authorId : _episode?.authorId;

  EpisodeModel? get _prev {
    if (_isStory) return null;
    final ep = _episode;
    if (ep == null) return null;
    final i = _siblings.indexWhere((e) => e.id == ep.id);
    return (i > 0) ? _siblings[i - 1] : null;
  }

  EpisodeModel? get _next {
    if (_isStory) return null;
    final ep = _episode;
    if (ep == null) return null;
    final i = _siblings.indexWhere((e) => e.id == ep.id);
    return (i >= 0 && i < _siblings.length - 1) ? _siblings[i + 1] : null;
  }

  Future<void> _loadFollowAuthor(String? authorId, {int? followerCount}) async {
    if (followerCount != null) _authorFollowerCount = followerCount;
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (authorId == null || authorId.isEmpty || me == null || me == authorId) {
      if (mounted) setState(() => _isFollowingAuthor = false);
      return;
    }
    try {
      final v = await _follow.isFollowing(authorId);
      if (mounted) setState(() => _isFollowingAuthor = v);
    } catch (_) {}
  }

  Future<void> _toggleFollowAuthor(String authorId) async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || me == authorId || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      final next = await _follow.toggleFollow(authorId);
      if (mounted) {
        setState(() {
          _isFollowingAuthor = next;
          _authorFollowerCount += next ? 1 : -1;
          if (_authorFollowerCount < 0) _authorFollowerCount = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
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
      _recordHistory();
    } catch (_) {
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
        _error = 'loadFailed';
        _loading = false;
      });
    }
  }

  Future<void> _loadStory() async {
    final story = await _storyService.getById(widget.id);
    if (story == null) throw Exception('notFound');

    final bm = await _bookmarkService.isStoryBookmarked(widget.id);
    final myR = await _reactionService.getMyStoryReaction(widget.id);
    final counts = await _reactionService.countStoryReactions(widget.id);
    final dl = await _offlineService.isDownloaded(widget.id);

    if (!mounted) return;
    setState(() {
      _story = story;
      _authorName = story.authorName ?? story.authorNickname;
      _authorAvatar = story.authorAvatar;
      _authorFollowerCount = story.authorFollowerCount;
      _loadFollowAuthor(story.authorId,
          followerCount: story.authorFollowerCount);
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
    if (ep == null) throw Exception('notFound');

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
      _authorName = novel?.authorName ?? novel?.authorNickname;
      _authorAvatar = novel?.authorAvatar;
      _myReaction = myR;
      _reactionTotal = counts.values.fold(0, (a, b) => a + b);
      _commentCount = ep.commentCount;
      _viewCount = ep.viewCount;
      _downloaded = dl;
    });
    _episodeService.recordView(ep.id);
  }

  Future<void> _recordHistory() async {
    try {
      if (_isStory && _story != null) {
        await _historyService.record(
          id: _story!.id,
          title: _story!.title,
          author: _story!.authorName,
          coverUrl: _story!.coverUrl,
          kind: 'story',
          progress: _progress,
        );
      } else if (!_isStory && _episode != null) {
        await _historyService.record(
          id: 'ep_${_episode!.id}',
          title: _episode!.title.isNotEmpty
              ? _episode!.title
              : 'Episode ${_episode!.chapterNumber}',
          author: _authorName,
          kind: 'episode',
          progress: _progress,
        );
      }
    } catch (_) {}
  }

  String _translateError(BuildContext context, Object e) {
    final raw = e.toString();
    final key = raw.replaceAll('Exception: ', '').trim();
    return context.l10n.t(key);
  }

  Future<void> _toggleBookmark() async {
    try {
      final on = _isStory
          ? await _bookmarkService.toggleStoryBookmark(widget.id)
          : await _bookmarkService.toggleEpisodeBookmark(widget.id);
      if (!mounted) return;
      setState(() => _bookmarked = on);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              on ? context.l10n.bookmarkAdded : context.l10n.bookmarkRemoved),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    }
  }

  Future<void> _download() async {
    final l10n = context.l10n;
    if (_downloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ইতিমধ্যে ডাউনলোড করা আছে')),
      );
      return;
    }

    setState(() => _downloading = true);
    try {
      if (_isStory) {
        final s = _story;
        if (s != null) await _offlineService.saveStory(s);
      } else {
        final ep = _episode;
        if (ep != null) {
          await _offlineService.saveEpisode(
            episodeId: ep.id,
            novelTitle: _novelTitle ?? '',
            episodeTitle: ep.title.isNotEmpty
                ? ep.title
                : '${l10n.episodeLabel} ${ep.chapterNumber}',
            chapterNumber: ep.chapterNumber,
            contentBlocks: ep.contentBlocks,
            authorName: _authorName ?? _story?.authorName,
            publicCode: ep.publicCode,
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _downloaded = true;
        _downloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.downloadedOffline)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    }
  }
  // lib/features/reader/presentation/screens/reader_screen.dart (Part 2)
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
        final counts = await _reactionService.countStoryReactions(widget.id);
        total = counts.values.fold(0, (a, b) => a + b);
      } else {
        result = await _reactionService.toggleEpisodeReaction(
          episodeId: widget.id,
          reactionType: type,
          ownerId: _ownerId,
        );
        final counts = await _reactionService.countEpisodeReactions(widget.id);
        total = counts.values.fold(0, (a, b) => a + b);
      }
      if (!mounted) return;
      setState(() {
        _myReaction = result;
        _reactionTotal = total;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
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
            ? CommentSection(storyId: widget.id, ownerId: _ownerId)
            : CommentSection(episodeId: widget.id, ownerId: _ownerId),
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
    final l10n = context.l10n;
    final code = _isStory ? _story?.publicCode : _episode?.publicCode;
    final title = _isStory
        ? (_story?.title ?? '')
        : '${_novelTitle ?? ''} — ${_episode?.title ?? ''}';
    await Share.share(
      '$title\n${l10n.shareReadOnApp}'
      '${code != null && code.isNotEmpty ? '\n${l10n.shareCodeLabel}: $code' : ''}\n#গল্পঘর',
    );
  }

  void _showFontSheet() {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.fontSize,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF050505),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _globalFontScale =
                                  (_globalFontScale - AppConstants.fontScaleStep)
                                      .clamp(
                                        AppConstants.minFontScale,
                                        AppConstants.maxFontScale,
                                      );
                            });
                            setModal(() {});
                          },
                          icon: const Icon(
                            Icons.text_decrease,
                            color: Color(0xFF050505),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _barGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(_globalFontScale * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _barGreen,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _globalFontScale =
                                  (_globalFontScale + AppConstants.fontScaleStep)
                                      .clamp(
                                        AppConstants.minFontScale,
                                        AppConstants.maxFontScale,
                                      );
                            });
                            setModal(() {});
                          },
                          icon: const Icon(
                            Icons.text_increase,
                            color: Color(0xFF050505),
                          ),
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

  void _showThemeSheet() {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.theme,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF050505),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _themeChip(
                            l10n.light,
                            ReaderTheme.light,
                            const Color(0xFFFFFFFF),
                            const Color(0xFF1C1E21),
                            () {
                              setState(
                                  () => _globalReaderTheme = ReaderTheme.light);
                              setModal(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _themeChip(
                            'Sepia',
                            ReaderTheme.sepia,
                            const Color(0xFFF5EEDB),
                            const Color(0xFF433422),
                            () {
                              setState(
                                  () => _globalReaderTheme = ReaderTheme.sepia);
                              setModal(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _themeChip(
                            l10n.dark,
                            ReaderTheme.dark,
                            const Color(0xFF18191A),
                            const Color(0xFFE4E6EB),
                            () {
                              setState(
                                  () => _globalReaderTheme = ReaderTheme.dark);
                              setModal(() {});
                            },
                          ),
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

  Widget _themeChip(
    String label,
    ReaderTheme theme,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    final selected = _globalReaderTheme == theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _barGreen : const Color(0xFFCED0D4),
            width: selected ? 2.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  // রিডারের ৩টি স্বাধীন মোড: Light, Sepia, Dark
  Color get _bgColor {
    switch (_globalReaderTheme) {
      case ReaderTheme.light:
        return const Color(0xFFFFFFFF);
      case ReaderTheme.sepia:
        return const Color(0xFFF5EEDB);
      case ReaderTheme.dark:
        return const Color(0xFF18191A);
    }
  }

  Color get _textColor {
    switch (_globalReaderTheme) {
      case ReaderTheme.light:
        return const Color(0xFF1C1E21);
      case ReaderTheme.sepia:
        return const Color(0xFF433422);
      case ReaderTheme.dark:
        return const Color(0xFFE4E6EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bg = _bgColor;
    final textPrimary = _textColor;
    final textSecondary = switch (_globalReaderTheme) {
      ReaderTheme.light => const Color(0xFF65676B),
      ReaderTheme.sepia => const Color(0xFF7A664E),
      ReaderTheme.dark => const Color(0xFFB0B3B8),
    };

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(color: _barGreen),
        ),
      );
    }

    if (_error != null && _story == null && _episode == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: _barGreen,
          foregroundColor: Colors.white,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.t(_error!), style: TextStyle(color: textPrimary)),
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: _barGreen),
                onPressed: _load,
                child: Text(l10n.again),
              ),
            ],
          ),
        ),
      );
    }

    final title = _isStory
        ? (_story?.title ?? '')
        : (_episode?.title.isNotEmpty == true
            ? _episode!.title
            : '${l10n.episodeLabel} ${_episode?.chapterNumber ?? 1}');

    final authorName = _authorName ?? _story?.authorName;
    final authorId = _isStory ? _story?.authorId : _episode?.authorId;
    final authorAvatar = _authorAvatar ?? _story?.authorAvatar;
    final publicCode = _isStory ? _story?.publicCode : _episode?.publicCode;
    final contentBlocks = _isStory
        ? (_story?.contentBlocks ?? [])
        : (_episode?.contentBlocks ?? []);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Column(
            children: [
              Material(
                color: _barGreen,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
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
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.flag_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                ReportSheet.show(
                                  context,
                                  targetType: _isStory ? 'story' : 'episode',
                                  targetId: widget.id,
                                  title: _isStory
                                      ? l10n.reportStory
                                      : l10n.reportEpisode,
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                      children: [
                        if (authorId != null && authorId.isNotEmpty) ...[
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (authorId.isNotEmpty) {
                                      context
                                          .push('${RouteNames.user}/$authorId');
                                    }
                                  },
                                  child: CachedAvatar(
                                    userId: authorId,
                                    imageUrl: authorAvatar,
                                    name: authorName ?? l10n.author,
                                    radius: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        authorName ?? l10n.author,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (Supabase.instance.client.auth
                                                .currentUser?.id !=
                                            null &&
                                        Supabase.instance.client.auth
                                                .currentUser?.id !=
                                            authorId) ...[
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: _followBusy
                                            ? null
                                            : () =>
                                                _toggleFollowAuthor(authorId),
                                        child: Icon(
                                          _isFollowingAuthor
                                              ? Icons.check_circle
                                              : Icons.add_circle_outline,
                                          size: 20,
                                          color: _barGreen,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_authorFollowerCount ${l10n.followers}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
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
                                  fontSize: (22 * _globalFontScale).toDouble(),
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  color: textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (Supabase.instance.client.auth
                                                .currentUser?.id !=
                                            null &&
                                        Supabase.instance.client.auth
                                                .currentUser?.id !=
                                            authorId) ...[
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: _followBusy
                                            ? null
                                            : () =>
                                                _toggleFollowAuthor(authorId),
                                        child: Icon(
                                          _isFollowingAuthor
                                              ? Icons.check_circle
                                              : Icons.add_circle_outline,
                                          size: 20,
                                          color: _barGreen,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_authorFollowerCount ${l10n.followers}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
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
                                  fontSize: (22 * _globalFontScale).toDouble(),
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
                                    color: _barGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    publicCode,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _barGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _barGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SelectionContainer.disabled(
                          child: ReaderContent(
                            blocks: contentBlocks,
                            fontScale: _globalFontScale,
                            textColor: textPrimary,
                            secondaryColor: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat(
                              Icons.remove_red_eye_outlined,
                              TimeAgo.compactOf(context, _viewCount),
                              textSecondary,
                            ),
                            GestureDetector(
                              onTap: _pickReaction,
                              child: _stat(
                                _myReaction != null
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                TimeAgo.compactOf(context, _reactionTotal),
                                _myReaction != null
                                    ? Colors.redAccent
                                    : textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _openComments,
                              child: _stat(
                                Icons.chat_bubble_outline,
                                TimeAgo.compactOf(context, _commentCount),
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
                    tooltip: l10n.download,
                    loading: _downloading,
                    onTap: _downloading ? null : _download,
                  ),
                  ReaderBottomBarItem(
                    icon: _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    tooltip: l10n.bookmark,
                    active: _bookmarked,
                    onTap: _toggleBookmark,
                  ),
                  ReaderBottomBarItem(
                    icon: Icons.text_fields,
                    tooltip: l10n.fontSize,
                    onTap: _showFontSheet,
                  ),
                  ReaderBottomBarItem(
                    icon: Icons.palette_outlined,
                    tooltip: l10n.theme,
                    onTap: _showThemeSheet,
                  ),
                  ReaderBottomBarItem(
                    icon: Icons.share_outlined,
                    tooltip: l10n.share,
                    onTap: _share,
                  ),
                ],
              ),
            ],
          ),
          if (!_isStory && (_prev != null || _next != null))
            Positioned(
              left: 16,
              right: 16,
              bottom: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_prev != null)
                    FloatingActionButton.small(
                      heroTag: 'prev_ep',
                      backgroundColor: _barGreen,
                      foregroundColor: Colors.white,
                      onPressed: () => context.pushReplacement(
                          '${RouteNames.episode}/${_prev!.id}'),
                      child: const Icon(Icons.chevron_left),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_next != null)
                    FloatingActionButton.small(
                      heroTag: 'next_ep',
                      backgroundColor: _barGreen,
                      foregroundColor: Colors.white,
                      onPressed: () => context.pushReplacement(
                          '${RouteNames.episode}/${_next!.id}'),
                      child: const Icon(Icons.chevron_right),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
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
         
