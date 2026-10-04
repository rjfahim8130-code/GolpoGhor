import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/episode_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/theme/app_colors.dart';
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
  final _scroll = ScrollController();

  EpisodeModel? _episode;
  List<EpisodeModel> _siblings = [];
  bool _loading = true;
  String? _error;
  double _fontScale = 1.0;
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
      setState(() {
        _episode = ep;
        _siblings = all;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _episode == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(_error ?? 'সমস্যা')),
      );
    }

    final ep = _episode!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prev = _prev;
    final next = _next;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ReaderWatermark()),
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverAppBar(
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'পর্ব ${ep.chapterNumber}',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.text_fields),
                    onPressed: () {
                      setState(() {
                        _fontScale =
                            _fontScale >= 1.4 ? 1.0 : _fontScale + 0.15;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: () => context.push('/novel/${ep.novelId}'),
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
              SliverContent(
                episode: ep,
                fontScale: _fontScale,
                isDark: isDark,
              ),
            ],
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: prev == null
                              ? null
                              : () => context.pushReplacement(
                                    '/episode/${prev.id}',
                                  ),
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('আগের'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: next == null
                              ? null
                              : () => context.pushReplacement(
                                    '/episode/${next.id}',
                                  ),
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('পরের'),
                        ),
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

class SliverContent extends StatelessWidget {
  final EpisodeModel episode;
  final double fontScale;
  final bool isDark;

  const SliverContent({
    super.key,
    required this.episode,
    required this.fontScale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.title,
              style: TextStyle(
                fontSize: 22 * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'পর্ব ${episode.chapterNumber} · ${episode.viewCount} দেখা',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SelectionContainer.disabled(
              child: ReaderContent(
                blocks: episode.contentBlocks,
                fontScale: fontScale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
