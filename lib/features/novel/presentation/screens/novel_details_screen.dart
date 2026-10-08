import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/ui_strings.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';

class NovelDetailsScreen extends StatefulWidget {
  final String novelId;

  const NovelDetailsScreen({super.key, required this.novelId});

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  final _novelService = NovelService();
  final _bookmarkService = BookmarkService();
  final _offlineService = OfflineService();
  final _auth = AuthService();

  NovelModel? _novel;
  List<EpisodeModel> _episodes = [];
  bool _loading = true;
  bool _bookmarked = false;
  bool _downloading = false;
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
        setState(() {
          _error = 'উপন্যাস পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }
      final episodes = await _novelService.getEpisodes(widget.novelId);
      final bm = await _bookmarkService.isNovelBookmarked(widget.novelId);
      setState(() {
        _novel = novel;
        _episodes = episodes;
        _bookmarked = bm;
        _loading = false;
      });
      _novelService.recordView('novel', widget.novelId);
    } catch (e) {
      setState(() {
        _error = 'লোড সমস্যা';
        _loading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final on = await _bookmarkService.toggleNovelBookmark(widget.novelId);
      setState(() => _bookmarked = on);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _share() async {
    final n = _novel;
    if (n == null) return;
    final code = n.publicCode ?? '';
    await Share.share(
      '${n.title}\nগল্পঘরে পড়ুন'
      '${code.isNotEmpty ? '\nকোড: $code' : ''}\n#গল্পঘর',
    );
  }

  Future<void> _downloadAll() async {
    if (_episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো পর্ব নেই')),
      );
      return;
    }
    setState(() => _downloading = true);
    try {
      for (final e in _episodes) {
        await _offlineService.saveStory(
          StoryModel(
            id: 'ep_${e.id}',
            authorId: e.authorId,
            title: '${_novel?.title ?? ''} — ${e.title}',
            description: 'পর্ব ${e.chapterNumber}',
            contentBlocks: e.contentBlocks,
            publicCode: e.publicCode,
            isPublished: true,
            createdAt: e.createdAt,
            authorName: _novel?.authorName,
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_episodes.length} পর্ব অফলাইনে সেভ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String? _episodeCover(EpisodeModel e) {
    for (final b in e.contentBlocks) {
      if (b.type == 'image' &&
          b.imageUrl != null &&
          b.imageUrl!.isNotEmpty) {
        return b.imageUrl;
      }
    }
    return null;
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _novel == null) {
      return Scaffold(
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
              Text(_error ?? 'সমস্যা'),
              TextButton(onPressed: _load, child: const Text('আবার')),
            ],
          ),
        ),
      );
    }

    final n = _novel!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
                    const Expanded(
                      child: Text(
                        'গল্পঘর উপন্যাস',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                          context.push('/user/${n.authorId}');
                        }
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            backgroundImage: n.authorAvatar != null &&
                                    n.authorAvatar!.isNotEmpty
                                ? CachedNetworkImageProvider(n.authorAvatar!)
                                : null,
                            child: n.authorAvatar == null ||
                                    n.authorAvatar!.isEmpty
                                ? Text(
                                    (n.authorName ?? 'ল')[0],
                                    style: const TextStyle(
                                      fontSize: 28,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
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
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.menu_book,
                          size: 48, color: AppColors.primary),
                    ),
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
                          ),
                        ),
                      ),
                      if (n.publicCode != null)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: n.publicCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('কোড কপি')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              n.publicCode!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (n.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(n.description,
                        style: const TextStyle(height: 1.45, fontSize: 14)),
                  ],

                  const SizedBox(height: 20),

                  // পর্ব গ্রিড
                  if (_episodes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('এখনো কোনো পর্ব নেই')),
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
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (context, i) {
                        final e = _episodes[i];
                        final cover = _episodeCover(e);
                        return Material(
                          color: Colors.white,
                          elevation: 1,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/episode/${e.id}'),
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
                                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                                  child: Text(
                                    e.title.isNotEmpty
                                        ? e.title
                                        : 'পর্ব ${e.chapterNumber}',
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
                                      Icon(Icons.remove_red_eye_outlined,
                                          size: 12,
                                          color: AppColors.lightTextSecondary),
                                      const SizedBox(width: 2),
                                      Text(
                                        _fmt(e.viewCount),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.favorite_border,
                                          size: 12,
                                          color: AppColors.lightTextSecondary),
                                      const SizedBox(width: 2),
                                      Text(
                                        _fmt(e.reactionCount),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      const Spacer(),
                                      Text(
                                        UiStrings.read,
                                        style: TextStyle(
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
            elevation: 8,
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: _downloading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      tooltip: 'অফলাইনে সেভ',
                      onPressed: _downloading ? null : _downloadAll,
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
                        onPressed: () =>
                            context.push('/add-episode/${n.id}'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          UiStrings.addEpisode,
                          style: TextStyle(color: Colors.white),
                        ),
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
