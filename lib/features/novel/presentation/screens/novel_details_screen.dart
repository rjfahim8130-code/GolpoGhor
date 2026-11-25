// lib/features/novel/presentation/screens/novel_details_screen.dart (Part 1)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../../../social/presentation/widgets/report_sheet.dart';

enum ReaderTheme { light, sepia, dark }

double _globalFontScale = AppConstants.defaultFontScale;
ReaderTheme _globalReaderTheme = ReaderTheme.light;

class NovelDetailsScreen extends StatefulWidget {
  final String novelId;
  const NovelDetailsScreen({super.key, required this.novelId});

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF242526);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _barGreen = Color(0xFF159447);

  final _follow = FollowService();
  bool _isFollowingAuthor = false;
  bool _followBusy = false;

  final _novelService = NovelService();
  final _episodeService = EpisodeService();
  final _bookmarkService = BookmarkService();
  final _offlineService = OfflineService();
  final _auth = AuthService();

  NovelModel? _novel;
  List<EpisodeModel> _episodes = [];
  bool _loading = true;
  bool _bookmarked = false;
  bool _downloadingAll = false;
  String? _error;

  bool get _isAuthor {
    final uid = _auth.currentUser?.id;
    return uid != null && _novel != null && _novel!.authorId == uid;
  }

  Future<void> _loadFollowAuthor(String authorId) async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || me == authorId || authorId.isEmpty) {
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
      if (mounted) setState(() => _isFollowingAuthor = next);
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
  }

  String _translateError(BuildContext context, Object e) {
    final raw = e.toString();
    final key = raw.replaceAll('Exception: ', '').trim();
    return context.l10n.t(key);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final novel = await _novelService.getById(widget.novelId);
      if (novel == null) {
        if (!mounted) return;
        setState(() {
          _error = 'novelNotFound';
          _loading = false;
        });
        return;
      }
      final episodes = await _episodeService.getByNovel(widget.novelId);
      final bm = await _bookmarkService.isNovelBookmarked(widget.novelId);

      if (!mounted) return;
      setState(() {
        _novel = novel;
        _episodes = episodes;
        _bookmarked = bm;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'loadFailed';
        _loading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final on = await _bookmarkService.toggleNovelBookmark(widget.novelId);
      if (!mounted) return;
      setState(() => _bookmarked = on);
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(on ? l10n.bookmarkAdded : l10n.bookmarkRemoved),
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

  Future<void> _share() async {
    final n = _novel;
    if (n == null) return;
    final l10n = context.l10n;
    final code = n.publicCode ?? '';
    await Share.share(
      '${n.title}\n${l10n.shareReadOnApp}'
      '${code.isNotEmpty ? '\n${l10n.shareCodeLabel}: $code' : ''}\n#গল্পঘর',
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copied)),
    );
  }

  Future<void> _downloadAll() async {
    final l10n = context.l10n;
    final n = _novel;
    if (n == null) return;
    if (_episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noEpisodes)),
      );
      return;
    }
    setState(() => _downloadingAll = true);
    try {
      for (final e in _episodes) {
        await _offlineService.saveEpisode(
          episodeId: e.id,
          novelTitle: n.title,
          episodeTitle: e.title.isNotEmpty
              ? e.title
              : '${l10n.episodeLabel} ${e.chapterNumber}',
          chapterNumber: e.chapterNumber,
          contentBlocks: e.contentBlocks,
          authorName: n.authorName,
          publicCode: e.publicCode,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_episodes.length} ${l10n.episodesSavedOffline}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  void _showFontAndThemeSheet() {
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
                padding: const EdgeInsets.all(24),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _globalFontScale = (_globalFontScale -
                                      AppConstants.fontScaleStep)
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
                            horizontal: 12,
                            vertical: 4,
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
                              _globalFontScale = (_globalFontScale +
                                      AppConstants.fontScaleStep)
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
                    const Divider(height: 24, color: Color(0xFFE4E6EB)),
                    Text(
                      l10n.theme,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF050505),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _themeChip(
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
                        _themeChip(
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
                        _themeChip(
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
        width: 80,
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

  String? _episodeCover(EpisodeModel e) {
    for (final b in e.contentBlocks) {
      if (b.isImage && b.imageUrl != null && b.imageUrl!.isNotEmpty) {
        return b.imageUrl;
      }
    }
    return null;
  }
  // lib/features/novel/presentation/screens/novel_details_screen.dart (Part 2A)
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const LoadingView());
    }

    if (_error != null || _novel == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: _barGreen,
          foregroundColor: Colors.white,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ErrorView(
          message: l10n.t(_error ?? 'problem'),
          onRetry: _load,
          retryLabel: l10n.retry,
        ),
      );
    }

    final n = _novel!;

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
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            l10n.novel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.flag_outlined,
                              color: Colors.white),
                          onPressed: () => ReportSheet.show(
                            context,
                            targetType: 'novel',
                            targetId: widget.novelId,
                            title: l10n.reportNovel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: _barGreen,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (n.authorId.isNotEmpty) {
                                  context.push('${RouteNames.user}/${n.authorId}');
                                }
                              },
                              child: CachedAvatar(
                                userId: n.authorId,
                                imageUrl: n.authorAvatar,
                                name: n.authorName ?? l10n.author,
                                radius: 34,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (n.authorId.isNotEmpty) {
                                        context.push(
                                            '${RouteNames.user}/${n.authorId}');
                                      }
                                    },
                                    child: Text(
                                      n.authorName ?? l10n.author,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: primaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (Supabase.instance.client.auth.currentUser
                                            ?.id !=
                                        null &&
                                    Supabase.instance.client.auth.currentUser
                                            ?.id !=
                                        n.authorId &&
                                    n.authorId.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _followBusy
                                        ? null
                                        : () => _toggleFollowAuthor(n.authorId),
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
                              '${n.authorFollowerCount} ${l10n.followers}',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (n.coverUrl != null && n.coverUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: n.coverUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder: (_, __) => Container(
                              height: 200,
                              color: _barGreen.withValues(alpha: 0.08),
                            ),
                            errorWidget: (_, __, ___) => _coverPlaceholder(),
                          ),
                        )
                      else
                        _coverPlaceholder(),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                color: primaryText,
                              ),
                            ),
                          ),
                          if (n.publicCode != null &&
                              n.publicCode!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _copyCode(n.publicCode!),
                              child: Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _barGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  n.publicCode!,
                                  style: const TextStyle(
                                    color: _barGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (n.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          n.description,
                          style: TextStyle(
                            height: 1.5,
                            fontSize: 14,
                            color: primaryText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _meta('${n.episodeCount} ${l10n.episode}',
                              Icons.list_alt, primaryText),
                          _meta(TimeAgo.compactOf(context, n.viewCount),
                              Icons.remove_red_eye_outlined, primaryText),
                          _meta(TimeAgo.compactOf(context, n.reactionCount),
                              Icons.favorite_border, primaryText),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: borderColor),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.viewAll} ${l10n.episode}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_episodes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              l10n.noEpisodesYet,
                              style: TextStyle(color: secondary),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _episodes.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.80,
                          ),
                          itemBuilder: (context, i) {
                            final e = _episodes[i];
                            final cover = _episodeCover(e);
                            return Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: borderColor, width: 1),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => context
                                    .push('${RouteNames.episode}/${e.id}'),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: cover != null
                                          ? CachedNetworkImage(
                                              imageUrl: cover,
                                              fit: BoxFit.cover,
                                              memCacheWidth: 400,
                                              errorWidget: (_, __, ___) =>
                                                  _epPlaceholder(e.chapterNumber),
                                            )
                                          : _epPlaceholder(e.chapterNumber),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          8, 8, 8, 4),
                                      child: Text(
                                        e.title.isNotEmpty
                                            ? e.title
                                            : '${l10n.episodeLabel} ${e.chapterNumber}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: primaryText,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          8, 0, 8, 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.remove_red_eye_outlined,
                                            size: 12,
                                            color: secondary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            TimeAgo.compactOf(
                                                context, e.viewCount),
                                            style: TextStyle(
                                                fontSize: 11, color: secondary),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.favorite_border,
                                            size: 12,
                                            color: secondary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            TimeAgo.compactOf(
                                                context, e.reactionCount),
                                            style: TextStyle(
                                                fontSize: 11, color: secondary),
                                          ),
                                          const Spacer(),
                                          Text(
                                            l10n.read,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _barGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              // lib/features/novel/presentation/screens/novel_details_screen.dart (Part 2B)
              Material(
                color: _barGreen,
                elevation: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          tooltip: l10n.downloadAllEpisodes,
                          color: Colors.white,
                          icon: _downloadingAll
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_outlined),
                          onPressed: _downloadingAll ? null : _downloadAll,
                        ),
                        IconButton(
                          tooltip: l10n.bookmark,
                          color: Colors.white,
                          icon: Icon(
                            _bookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          onPressed: _toggleBookmark,
                        ),
                        IconButton(
                          tooltip: l10n.fontSize,
                          color: Colors.white,
                          icon: const Icon(Icons.text_fields),
                          onPressed: _showFontAndThemeSheet,
                        ),
                        IconButton(
                          tooltip: l10n.theme,
                          color: Colors.white,
                          icon: const Icon(Icons.palette_outlined),
                          onPressed: _showFontAndThemeSheet,
                        ),
                        IconButton(
                          tooltip: l10n.share,
                          color: Colors.white,
                          icon: const Icon(Icons.share_outlined),
                          onPressed: _share,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isAuthor)
            Positioned(
              right: 16,
              bottom: 70,
              child: FloatingActionButton.extended(
                backgroundColor: cardColor,
                foregroundColor: _barGreen,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                onPressed: () =>
                    context.push('${RouteNames.addEpisode}/${n.id}'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  l10n.addEpisode,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _meta(String label, IconData icon, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _barGreen),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: _barGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(Icons.menu_book, size: 52, color: _barGreen),
      ),
    );
  }

  Widget _epPlaceholder(int num) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Container(
      color: _barGreen.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Text(
        isBn ? 'পর্ব $num' : 'Episode $num',
        style: const TextStyle(
          color: _barGreen,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
