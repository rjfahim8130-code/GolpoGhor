// lib/features/novel/presentation/screens/novel_details_screen.dart
// সংশোধিত: localization, avatar cache

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../../../social/presentation/widgets/report_sheet.dart';

class NovelDetailsScreen extends StatefulWidget {
  final String novelId;

  const NovelDetailsScreen({super.key, required this.novelId});

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
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
      final novel = await _novelService.getById(widget.novelId);
      if (novel == null) {
        if (!mounted) return;
        setState(() {
          _error = 'উপন্যাস পাওয়া যায়নি';
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

      _novelService.recordView(widget.novelId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final on = await _bookmarkService.toggleNovelBookmark(widget.novelId);
      if (!mounted) return;
      setState(() => _bookmarked = on);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(on ? 'বুকমার্ক করা হয়েছে' : 'বুকমার্ক সরানো হয়েছে'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _share() async {
    final n = _novel;
    if (n == null) return;
    final code = n.publicCode ?? '';
    await Share.share(
      '${n.title}\nগল্পঘরে পড়ুন'
      '${code.isNotEmpty ? '\nকোড: $code' : ''}\n#গল্পঘর',
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copied)),
    );
  }

  Future<void> _downloadAll() async {
    final n = _novel;
    if (n == null) return;
    if (_episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো পর্ব নেই')),
      );
      return;
    }
    setState(() => _downloadingAll = true);
    try {
      for (final e in _episodes) {
        await _offlineService.saveEpisode(
          episodeId: e.id,
          novelTitle: n.title,
          episodeTitle: e.title,
          chapterNumber: e.chapterNumber,
          contentBlocks: e.contentBlocks,
          authorName: n.authorName,
          publicCode: e.publicCode,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_episodes.length} পর্ব অফলাইনে সেভ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  String? _episodeCover(EpisodeModel e) {
    for (final b in e.contentBlocks) {
      if (b.isImage && b.imageUrl != null && b.imageUrl!.isNotEmpty) {
        return b.imageUrl;
      }
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const LoadingView());
    }

    if (_error != null || _novel == null) {
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
        body: ErrorView(message: _error ?? 'সমস্যা', onRetry: _load),
      );
    }

    final n = _novel!;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // সবুজ টপ বার
          Material(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      icon: const Icon(
                        Icons.flag_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => ReportSheet.show(
                        context,
                        targetType: 'novel',
                        targetId: widget.novelId,
                        title: 'উপন্যাস রিপোর্ট',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // কনটেন্ট
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // লেখক
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (n.authorId.isNotEmpty) {
                          context.push('${RouteNames.user}/${n.authorId}');
                        }
                      },
                      child: Column(
                        children: [
                          CachedAvatar(
                            userId: n.authorId,
                            imageUrl: n.authorAvatar,
                            name: n.authorName ?? 'লেখক',
                            radius: 34,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            n.authorName ?? 'লেখক',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // কভার
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
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        errorWidget: (_, __, ___) => _coverPlaceholder(),
                      ),
                    )
                  else
                    _coverPlaceholder(),
                  const SizedBox(height: 14),

                  // নাম + কোড
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
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
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              n.publicCode!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // বিবরণ
                  if (n.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      n.description,
                      style: const TextStyle(height: 1.5, fontSize: 14),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // মেটা
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _meta('${n.episodeCount} ${l10n.episode}', Icons.list_alt),
                      _meta(
                        TimeAgo.compact(n.viewCount),
                        Icons.remove_red_eye_outlined,
                      ),
                      _meta(
                        TimeAgo.compact(n.reactionCount),
                        Icons.favorite_border,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'সব ${l10n.episode}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // পর্ব গ্রিড
                  if (_episodes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'এখনো কোনো পর্ব নেই',
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
                        return Material(
                          color: cardColor,
                          elevation: 0,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context
                                .push('${RouteNames.episode}/${e.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 8, 8, 4),
                                  child: Text(
                                    e.title.isNotEmpty
                                        ? e.title
                                        : '${l10n.episode} ${e.chapterNumber}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.remove_red_eye_outlined,
                                        size: 12,
                                        color: secondary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        TimeAgo.compact(e.viewCount),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: secondary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.favorite_border,
                                        size: 12,
                                        color: secondary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        TimeAgo.compact(e.reactionCount),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: secondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        l10n.read,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
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

          // নিচের বার
          Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'সব পর্ব ডাউনলোড',
                      icon: _downloadingAll
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      onPressed: _downloadingAll ? null : _downloadAll,
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
                    const Spacer(),
                    if (_isAuthor)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => context.push(
                          '${RouteNames.addEpisode}/${n.id}',
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.addEpisode),
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

  Widget _meta(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(Icons.menu_book, size: 52, color: AppColors.primary),
      ),
    );
  }

  Widget _epPlaceholder(int num) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Text(
        'পর্ব $num',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
