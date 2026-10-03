import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/search_service.dart';
import '../../../../core/theme/app_colors.dart';
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

  Timer? _debounce;
  bool _loading = false;
  SearchResult? _result;
  List<String> _recent = [];
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecent();
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

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recent = prefs.getStringList('search_recent') ?? [];
    });
  }

  Future<void> _saveRecent(String q) async {
    final t = q.trim();
    if (t.length < 2) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('search_recent') ?? [];
    list.remove(t);
    list.insert(0, t);
    if (list.length > 10) list.removeRange(10, list.length);
    await prefs.setStringList('search_recent', list);
    setState(() => _recent = list);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_recent');
    setState(() => _recent = []);
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
      await _saveRecent(q);
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
          decoration: const InputDecoration(
            hintText: 'গল্প, লেখক বা কোড…',
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
              ? _buildIdle(isDark)
              : _buildResults(isDark),
    );
  }

  Widget _buildIdle(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recent.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'সাম্প্রতিক',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearRecent,
                child: const Text('সব মুছুন'),
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
        const Text(
          'ক্যাটাগরি',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.categories
              .map(
                (c) => ActionChip(
                  label: Text(c),
                  onPressed: () => context.push(
                    '/category/${Uri.encodeComponent(c)}',
                  ),
                ),
              )
              .toList(),
          ),
        const SizedBox(height: 24),
        Text(
          'লেখকের কোড বা GS-XXXX গল্প কোড লিখলে সরাসরি পাওয়া যাবে।',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildResults(bool isDark) {
    final r = _result;
    if (r == null) return const SizedBox.shrink();
    if (r.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'কোনো ফলাফল নেই — অন্য শব্দ বা কোড চেষ্টা করুন',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
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
          _sectionTitle('কোড মিলেছে', highlight: true),
          if (r.exactStoryCode != null)
            StoryCard(
              story: r.exactStoryCode!,
              onTap: () => context.push('/story/${r.exactStoryCode!.id}'),
            ),
          if (r.exactNovelCode != null)
            NovelCard(
              novel: r.exactNovelCode!,
              onTap: () => context.push('/novel/${r.exactNovelCode!.id}'),
            ),
          if (r.exactUserCode != null)
            _authorTile(r.exactUserCode!),
        ],
        if (r.authors.isNotEmpty) ...[
          _sectionTitle('লেখক (${r.authors.length})'),
          ...r.authors.map(_authorTile),
        ],
        if (r.stories.isNotEmpty) ...[
          _sectionTitle('গল্প (${r.stories.length})'),
          ...r.stories.map(
            (s) => StoryCard(
              story: s,
              onTap: () => context.push('/story/${s.id}'),
            ),
          ),
        ],
        if (r.novels.isNotEmpty) ...[
          _sectionTitle('উপন্যাস (${r.novels.length})'),
          ...r.novels.map(
            (n) => NovelCard(
              novel: n,
              onTap: () => context.push('/novel/${n.id}'),
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

  Widget _authorTile(UserModel u) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage:
            u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                ? NetworkImage(u.avatarUrl!)
                : null,
        child: u.avatarUrl == null || u.avatarUrl!.isEmpty
            ? Text(
                u.displayName.isNotEmpty ? u.displayName[0] : '?',
                style: const TextStyle(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(u.displayName),
      subtitle: Text(
        [
          if (u.username != null) '@${u.username}',
          if (u.inviteCode != null) u.inviteCode!,
        ].join(' · '),
      ),
      onTap: () => context.push('/user/${u.id}'),
    );
  }
}
