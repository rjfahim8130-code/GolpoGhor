// lib/features/search/presentation/screens/search_screen.dart (Part 1)
// সংশোধিত: SearchSuggestionService ও CategoryCatalog যুক্ত

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/search_service.dart';
import '../../../../core/services/search_suggestion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';
import '../../../home/presentation/widgets/novel_card.dart';
import '../../../home/presentation/widgets/story_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _searchService = SearchService();
  final _suggestions = SearchSuggestionService();

  Timer? _debounce;
  bool _loading = false;
  SearchResult? _result;
  List<String> _recent = [];
  List<String> _topSearches = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final top = await _suggestions.topQueries(limit: 10);
    final recent = await _suggestions.recent();
    if (!mounted) return;
    setState(() {
      _topSearches = top;
      _recent = recent;
    });
  }

  Future<void> _clearRecent() async {
    await _suggestions.clearRecent();
    final recent = await _suggestions.recent();
    if (mounted) setState(() => _recent = recent);
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => _runSearch(v),
    );
  }

  Future<void> _runSearch(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _loading = false;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _lastQuery = q;
    });
    try {
      final r = await _searchService.search(q);
      if (!mounted || _lastQuery != q) return;
      setState(() {
        _result = r;
        _loading = false;
      });
      await _suggestions.recordQuery(q);
      await _loadSuggestions();
    } catch (_) {
      if (mounted && _lastQuery == q) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: q.length),
    );
    _runSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showIdle = !_loading && _result == null && _controller.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _runSearch,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _result = null;
                  _lastQuery = '';
                });
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : showIdle
              ? _buildIdle(l10n, isDark)
              : _buildResults(l10n, isDark),
    );
  }
  // lib/features/search/presentation/screens/search_screen.dart (Part 2)

  Widget _buildIdle(AppLocalizations l10n, bool isDark) {
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ============ Popular & Trending বাটন ============
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(RouteNames.popular),
                  icon: const Icon(Icons.star_outline),
                  label: Text(l10n.popular),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(RouteNames.trending),
                  icon: const Icon(Icons.local_fire_department_outlined),
                  label: Text(l10n.trending),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ============ Popular Searches (Frequency) ============
        if (_topSearches.isNotEmpty) ...[
          Text(
            l10n.popularSearches,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topSearches
                .map(
                  (q) => ActionChip(
                    avatar: const Icon(Icons.trending_up, size: 16),
                    label: Text(q),
                    onPressed: () => _applyQuery(q),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ============ Recent Searches ============
        if (_recent.isNotEmpty) ...[
          Row(
            children: [
              Text(
                l10n.recent,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearRecent,
                child: Text(l10n.clearAll),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recent
                .map(
                  (r) => ActionChip(
                    label: Text(r),
                    onPressed: () => _applyQuery(r),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ============ Categories (Writing Groups) ============
        Text(
          l10n.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CategoryCatalog.writingGroups.map((g) {
            return ActionChip(
              label: Text(l10n.t(g)),
              onPressed: () {
                context.push('${RouteNames.category}?key=$g');
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.searchCodeHint,
          style: TextStyle(fontSize: 13, color: secondary),
        ),
      ],
    );
  }

  Widget _buildResults(AppLocalizations l10n, bool isDark) {
    final r = _result;
    if (r == null) return const SizedBox.shrink();
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (r.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.noSearchResults,
            textAlign: TextAlign.center,
            style: TextStyle(color: secondary),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (r.exactStoryCode != null ||
            r.exactNovelCode != null ||
            r.exactUserCode != null) ...[
          _sectionTitle(l10n.codeMatched, highlight: true),
          if (r.exactStoryCode != null)
            StoryCard(
              story: r.exactStoryCode!,
              onTap: () => context.push(
                '${RouteNames.story}/${r.exactStoryCode!.id}',
              ),
            ),
          if (r.exactNovelCode != null)
            NovelCard(
              novel: r.exactNovelCode!,
              onTap: () => context.push(
                '${RouteNames.novel}/${r.exactNovelCode!.id}',
              ),
            ),
          if (r.exactUserCode != null) _authorTile(r.exactUserCode!, l10n),
        ],
        if (r.authors.isNotEmpty) ...[
          _sectionTitle('${l10n.authors} (${r.authors.length})'),
          ...r.authors.map((a) => _authorTile(a, l10n)),
        ],
        if (r.stories.isNotEmpty) ...[
          _sectionTitle('${l10n.story} (${r.stories.length})'),
          ...r.stories.map(
            (s) => StoryCard(
              story: s,
              onTap: () => context.push('${RouteNames.story}/${s.id}'),
            ),
          ),
        ],
        if (r.novels.isNotEmpty) ...[
          _sectionTitle('${l10n.novel} (${r.novels.length})'),
          ...r.novels.map(
            (n) => NovelCard(
              novel: n,
              onTap: () => context.push('${RouteNames.novel}/${n.id}'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: highlight ? AppColors.primary : null,
        ),
      ),
    );
  }

  Widget _authorTile(UserModel u, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ListTile(
      leading: CachedAvatar(
        userId: u.id,
        imageUrl: u.avatarUrl,
        name: u.displayNameOr(l10n.user),
        radius: 22,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              u.displayNameOr(l10n.user),
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (u.isAdmin) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.shield,
              size: 14,
              color: AppColors.danger,
            ),
          ],
        ],
      ),
      subtitle: u.hasNickname
          ? Text(
              u.displayNickname,
              style: TextStyle(
                fontSize: 12,
                color: secondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () => context.push('${RouteNames.user}/${u.id}'),
    );
  }
}
