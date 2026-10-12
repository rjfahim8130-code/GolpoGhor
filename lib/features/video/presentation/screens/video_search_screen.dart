// lib/features/video/presentation/screens/video_search_screen.dart
// শুধু ভিডিও — SearchService.searchVideos()

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/video_model.dart';
import '../../../../core/services/search_service.dart';
import '../../../../core/services/search_suggestion_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

class VideoSearchScreen extends StatefulWidget {
  const VideoSearchScreen({super.key});

  @override
  State<VideoSearchScreen> createState() => _VideoSearchScreenState();
}

class _VideoSearchScreenState extends State<VideoSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _search = SearchService();
  final _suggestions = SearchSuggestionService();

  // ভিডিও trending আলাদা key চাইলে service-এ namespace prefix দিন
  // এখনকার recordQuery একই local map ব্যবহার করতে পারে

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
    _controller.selection =
        TextSelection.collapsed(offset: q.length);
    _run(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _run,
          decoration: InputDecoration(
            hintText: l10n.searchHint, // বা videoSearchHint key
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
          ? const Center(child: CircularProgressIndicator())
          : _last.isEmpty
              ? _buildIdle(l10n)
              : _results.isEmpty
                  ? Center(child: Text(l10n.noSearchResults))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final v = _results[i];
                        return ListTile(
                          leading: const Icon(Icons.videocam_outlined),
                          title: Text(
                            v.title.trim().isEmpty
                                ? l10n.video
                                : v.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            v.authorName ?? l10n.author,
                            maxLines: 1,
                          ),
                          onTap: () {
                            // ফিডে নির্দিষ্ট ভিডিও খুলতে চাইলে id পাস করুন
                            context.push(RouteNames.videos);
                          },
                        );
                      },
                    ),
    );
  }

  Widget _buildIdle(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_top.isNotEmpty) ...[
          Text(l10n.popularSearches,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _top
                .map((q) => ActionChip(
                      label: Text(q),
                      onPressed: () => _apply(q),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text(l10n.category,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CategoryCatalog.videoGroups.map((g) {
            return ActionChip(
              label: Text(l10n.t(g)),
              onPressed: () => _apply(l10n.t(g)),
              // উন্নত: category key দিয়ে filter API
            );
          }).toList(),
        ),
      ],
    );
  }
}
