// lib/features/profile/presentation/screens/saved_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../../../home/presentation/widgets/novel_card.dart';
import '../../../home/presentation/widgets/story_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);

  late TabController _tab;
  final _bookmarkService = BookmarkService();

  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stories = await _bookmarkService.getSavedStories();
      final novels = await _bookmarkService.getSavedNovels();
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _novels = novels;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.loadFailed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.saved),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Divider(height: 1, color: borderColor),
              TabBar(
                controller: _tab,
                labelColor: _brandGreen,
                unselectedLabelColor: secondaryText,
                indicatorColor: _brandGreen,
                tabs: [
                  Tab(text: l10n.story),
                  Tab(text: l10n.novel),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tab,
                  children: [
                    _stories.isEmpty
                        ? EmptyView(
                            icon: Icons.bookmark_outline,
                            title: l10n.noSavedStories,
                          )
                        : RefreshIndicator(
                            color: _brandGreen,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _stories.length,
                              itemBuilder: (_, i) {
                                final s = _stories[i];
                                return StoryCard(
                                  story: s,
                                  onTap: () => context.push(
                                    '${RouteNames.story}/${s.id}',
                                  ),
                                );
                              },
                            ),
                          ),
                    _novels.isEmpty
                        ? EmptyView(
                            icon: Icons.bookmark_outline,
                            title: l10n.noSavedNovels,
                          )
                        : RefreshIndicator(
                            color: _brandGreen,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _novels.length,
                              itemBuilder: (_, i) {
                                final n = _novels[i];
                                return NovelCard(
                                  novel: n,
                                  onTap: () => context.push(
                                    '${RouteNames.novel}/${n.id}',
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
    );
  }
}
