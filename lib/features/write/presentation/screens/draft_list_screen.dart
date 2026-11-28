// lib/features/write/presentation/screens/draft_list_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';

class DraftListScreen extends StatefulWidget {
  const DraftListScreen({super.key});

  @override
  State<DraftListScreen> createState() => _DraftListScreenState();
}

class _DraftListScreenState extends State<DraftListScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

  final _storyService = StoryService();
  final _novelService = NovelService();

  List<StoryModel> _storyDrafts = [];
  List<NovelModel> _novelDrafts = [];
  bool _loading = true;
  String? _error;

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
      final s = await _storyService.getMyStories(draftsOnly: true);
      final allNovels = await _novelService.getMyNovels();
      final nd = allNovels.where((n) => n.isDraft).toList();

      if (!mounted) return;
      setState(() {
        _storyDrafts = s;
        _novelDrafts = nd;
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

  Future<void> _deleteStory(StoryModel s) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(s.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: _dangerColor),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _storyService.deleteStory(s.id);
    await _load();
  }

  Future<void> _deleteNovel(NovelModel n) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(n.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: _dangerColor),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _novelService.deleteNovel(n.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final empty = _storyDrafts.isEmpty && _novelDrafts.isEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.drafts),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(
                  message: l10n.t(_error!),
                  onRetry: _load,
                  retryLabel: l10n.retry,
                )
              : empty
                  ? EmptyView(
                      icon: Icons.drafts_outlined,
                      title: l10n.noDrafts,
                    )
                  : RefreshIndicator(
                      color: _brandGreen,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          if (_storyDrafts.isNotEmpty) ...[
                            _sectionTitle(l10n.story, secondary),
                            ..._storyDrafts.map((s) {
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      s.title.isEmpty ? l10n.untitled : s.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: primaryText),
                                    ),
                                    subtitle: Text(
                                      s.updatedAt != null
                                          ? '${l10n.updatedOn}: ${s.updatedAt!.day}/${s.updatedAt!.month}/${s.updatedAt!.year}'
                                          : '',
                                      style: TextStyle(color: secondary),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      iconColor: secondary,
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          context.push(
                                            '${RouteNames.writeStory}/${s.id}',
                                          );
                                        }
                                        if (v == 'delete') _deleteStory(s);
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(l10n.edit),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            l10n.delete,
                                            style: const TextStyle(
                                              color: _dangerColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => context.push(
                                      '${RouteNames.writeStory}/${s.id}',
                                    ),
                                  ),
                                  Divider(height: 1, color: borderColor),
                                ],
                              );
                            }),
                          ],
                          if (_novelDrafts.isNotEmpty) ...[
                            _sectionTitle(l10n.novel, secondary),
                            ..._novelDrafts.map((n) {
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      n.title.isEmpty ? l10n.untitled : n.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: primaryText),
                                    ),
                                    subtitle: Text(
                                      n.updatedAt != null
                                          ? '${l10n.updatedOn}: ${n.updatedAt!.day}/${n.updatedAt!.month}/${n.updatedAt!.year}'
                                          : '',
                                      style: TextStyle(color: secondary),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      iconColor: secondary,
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          context.push(
                                            '${RouteNames.writeNovel}/${n.id}',
                                          );
                                        }
                                        if (v == 'delete') _deleteNovel(n);
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(l10n.edit),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            l10n.delete,
                                            style: const TextStyle(
                                              color: _dangerColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => context.push(
                                      '${RouteNames.writeNovel}/${n.id}',
                                    ),
                                  ),
                                  Divider(height: 1, color: borderColor),
                                ],
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _sectionTitle(String text, Color secondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
      ),
    );
  }
}
