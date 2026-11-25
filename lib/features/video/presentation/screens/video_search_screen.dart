// lib/features/video/presentation/screens/video_search_screen.dart
// শুধু ভিডিও — SearchService.searchVideos() + focus query fix + Updated Imports

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/video_model.dart';
import '../../../../core/services/search_service.dart';
import '../../../../core/services/search_suggestion_service.dart';
import '../../../../routing/route_names.dart';

class VideoSearchScreen extends StatefulWidget {
  const VideoSearchScreen({super.key});

  @override
  State<VideoSearchScreen> createState() => _VideoSearchScreenState();
}

class _VideoSearchScreenState extends State<VideoSearchScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _search = SearchService();
  final _suggestions = SearchSuggestionService();

  Timer? _debounce;
  bool _loading = false;
  List<VideoModel> _results = [];
  List<String> _top = [];
  List<String> _recent = [];
  String _last = '';

  @override
  void initState() {
    super.initState();
    _loadMeta();
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

  Future<void> _loadMeta() async {
    final top = await _suggestions.topQueries(limit: 10);
    final recent = await _suggestions.recent();
    if (!mounted) return;
    setState(() {
      _top = top;
      _recent = recent;
    });
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(v));
  }

  Future<void> _run(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _last = '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _last = q;
    });
    try {
      final list = await _search.searchVideos(q);
      await _suggestions.recordQuery(q);
      if (!mounted) return;
      setState(() {
        _results = list;
        _loading = false;
      });
      await _loadMeta();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  void _apply(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _run(q);
  }

  void _openVideo(VideoModel v) {
    context.push('${RouteNames.videos}?focus=${v.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _run,
          style: TextStyle(color: primaryText),
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            hintStyle: TextStyle(color: secondary),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _results = [];
                  _last = '';
                });
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _brandGreen),
            )
          : _last.isEmpty
              ? _buildIdle(l10n, isDark)
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noSearchResults,
                        style: TextStyle(color: secondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final v = _results[i];
                        return ListTile(
                          leading: const Icon(
                            Icons.videocam_outlined,
                            color: _brandGreen,
                          ),
                          title: Text(
                            v.displayTitleOr(l10n.video),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: primaryText),
                          ),
                          subtitle: Text(
                            v.authorName ?? l10n.author,
                            maxLines: 1,
                            style: TextStyle(color: secondary),
                          ),
                          onTap: () => _openVideo(v),
                        );
                      },
                    ),
    );
  }

  Widget _buildIdle(AppLocalizations l10n, bool isDark) {
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final chipBg =
        isDark ? const Color(0xFF242526) : const Color(0xFFF0F2F5);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_top.isNotEmpty) ...[
          Text(
            l10n.popularSearches,
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _top
                .map((q) => ActionChip(
                      backgroundColor: chipBg,
                      side: BorderSide(color: borderColor),
                      label: Text(q, style: TextStyle(color: primaryText)),
                      onPressed: () => _apply(q),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (_recent.isNotEmpty) ...[
          Text(
            l10n.recent,
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recent
                .map((q) => ActionChip(
                      backgroundColor: chipBg,
                      side: BorderSide(color: borderColor),
                      label: Text(q, style: TextStyle(color: primaryText)),
                      onPressed: () => _apply(q),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          l10n.category,
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CategoryCatalog.videoGroups.map((g) {
            return ActionChip(
              backgroundColor: chipBg,
              side: BorderSide(color: borderColor),
              label: Text(l10n.t(g), style: TextStyle(color: primaryText)),
              onPressed: () => _apply(l10n.t(g)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.searchCodeHint,
          style: TextStyle(fontSize: 13, color: secondary),
        ),
      ],
    );
  }
}
