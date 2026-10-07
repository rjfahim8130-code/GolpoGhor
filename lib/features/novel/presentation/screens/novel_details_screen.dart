import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/episode_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/novel_service.dart';
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
  final _auth = AuthService();

  NovelModel? _novel;
  List<EpisodeModel> _episodes = [];
  bool _loading = true;
  bool _bookmarked = false;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
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
      ),
      floatingActionButton: _isAuthor
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/add-episode/${n.id}'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('পর্ব যোগ', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            if (n.coverUrl != null && n.coverUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: n.coverUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book, size: 48, color: AppColors.primary),
              ),
            const SizedBox(height: 16),
            Text(
              n.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                if (n.authorId.isNotEmpty) {
                  context.push('/user/${n.authorId}');
                }
              },
              child: Text(
                n.authorName ?? 'লেখক',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (n.publicCode != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: n.publicCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('কোড কপি')),
                  );
                },
                child: Text(
                  'কোড: ${n.publicCode}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${n.episodeCount} পর্ব · ${n.viewCount} দেখা',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            if (n.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(n.description, style: const TextStyle(height: 1.45)),
            ],
            const SizedBox(height: 20),
            const Text(
              'পর্বসমূহ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_episodes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('এখনো কোনো পর্ব নেই')),
              )
            else
              ..._episodes.map((e) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        '${e.chapterNumber}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(e.title),
                    subtitle: Text(
                      [
                        '${e.viewCount} দেখা',
                        if (e.publicCode != null) e.publicCode!,
                        if (!e.isPublished || (e is EpisodeModel && false)) '',
                      ].where((s) => s.isNotEmpty).join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (e.publicCode != null)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: e.publicCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('পর্বের কোড কপি')),
                              );
                            },
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => context.push('/episode/${e.id}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
