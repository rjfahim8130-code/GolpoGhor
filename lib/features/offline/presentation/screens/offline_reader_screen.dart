// lib/features/offline/presentation/screens/offline_reader_screen.dart (Part 1)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../../../reader/presentation/widgets/reader_bottom_bar.dart';
import '../../../reader/presentation/widgets/reader_content.dart';
import '../../../reader/presentation/widgets/reader_watermark.dart';

enum ReaderTheme { light, sepia, dark }

double _globalFontScale = AppConstants.defaultFontScale;
ReaderTheme _globalReaderTheme = ReaderTheme.light;

class OfflineReaderScreen extends StatefulWidget {
  final String itemId;
  const OfflineReaderScreen({super.key, required this.itemId});

  @override
  State<OfflineReaderScreen> createState() => _OfflineReaderScreenState();
}

class _OfflineReaderScreenState extends State<OfflineReaderScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _textLight = Color(0xFF000000);
  static const Color _textDark = Color(0xFFFFFFFF);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

  final _service = OfflineService();
  final _episodeService = EpisodeService();
  final _scroll = ScrollController();

  OfflineItem? _item;
  bool _loading = true;
  double _progress = 0;
  List<EpisodeModel> _siblings = [];

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
    final item = await _service.get(widget.itemId);
    if (item != null && item.novelId != null) {
      try {
        _siblings = await _episodeService.getByNovel(item.novelId!);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  EpisodeModel? get _prev {
    final item = _item;
    if (item == null || item.novelId == null || _siblings.isEmpty) return null;
    final cleanId = widget.itemId.startsWith('ep_')
        ? widget.itemId.substring(3)
        : widget.itemId;
    final i = _siblings.indexWhere((e) => e.id == cleanId);
    return (i > 0) ? _siblings[i - 1] : null;
  }

  EpisodeModel? get _next {
    final item = _item;
    if (item == null || item.novelId == null || _siblings.isEmpty) return null;
    final cleanId = widget.itemId.startsWith('ep_')
        ? widget.itemId.substring(3)
        : widget.itemId;
    final i = _siblings.indexWhere((e) => e.id == cleanId);
    return (i >= 0 && i < _siblings.length - 1) ? _siblings[i + 1] : null;
  }

  void _showFontSheet() {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final primaryText = isDark ? _textDark : _textLight;
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.fontSize,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _globalFontScale = (_globalFontScale -
                                      AppConstants.fontScaleStep)
                                  .clamp(
                                AppConstants.minFontScale,
                                AppConstants.maxFontScale,
                              );
                            });
                            setModal(() {});
                          },
                          icon: Icon(Icons.text_decrease, color: primaryText),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _brandGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(_globalFontScale * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _brandGreen,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _globalFontScale = (_globalFontScale +
                                      AppConstants.fontScaleStep)
                                  .clamp(
                                AppConstants.minFontScale,
                                AppConstants.maxFontScale,
                              );
                            });
                            setModal(() {});
                          },
                          icon: Icon(Icons.text_increase, color: primaryText),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: borderColor),
                    Text(
                      l10n.theme,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _themeChip(
                          l10n.light,
                          ReaderTheme.light,
                          const Color(0xFFFFFFFF),
                          const Color(0xFF000000),
                          () {
                            setState(() => _globalReaderTheme = ReaderTheme.light);
                            setModal(() {});
                          },
                        ),
                        _themeChip(
                          'Sepia',
                          ReaderTheme.sepia,
                          AppColors.sepiaBg,
                          AppColors.sepiaText,
                          () {
                            setState(() => _globalReaderTheme = ReaderTheme.sepia);
                            setModal(() {});
                          },
                        ),
                        _themeChip(
                          l10n.dark,
                          ReaderTheme.dark,
                          const Color(0xFF18191A),
                          const Color(0xFFFFFFFF),
                          () {
                            setState(() => _globalReaderTheme = ReaderTheme.dark);
                            setModal(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _themeChip(
    String label,
    ReaderTheme theme,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    final selected = _globalReaderTheme == theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _brandGreen : const Color(0xFFE4E6EB),
            width: selected ? 2.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    final item = _item;
    if (item == null) return;
    final l10n = context.l10n;
    final code = item.publicCode ?? '';
    await Share.share(
      '${item.title}\n\n${l10n.shareReadOnApp}'
      '${code.isNotEmpty ? '\n${l10n.shareCodeLabel}: $code' : ''}\n#গল্পঘর',
    );
  }

  Future<void> _deleteOffline() async {
    final item = _item;
    if (item == null) return;
    final l10n = context.l10n;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(item.title),
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

    await _service.remove(widget.itemId);
    if (!mounted) return;
    context.pop();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  Color get _bgColor {
    switch (_globalReaderTheme) {
      case ReaderTheme.light:
        return Theme.of(context).brightness == Brightness.dark ? _bgDark : _bgLight;
      case ReaderTheme.sepia:
        return AppColors.sepiaBg;
      case ReaderTheme.dark:
        return _bgDark;
    }
  }

  Color get _textColor {
    switch (_globalReaderTheme) {
      case ReaderTheme.light:
        return Theme.of(context).brightness == Brightness.dark
            ? _textDark
            : _textLight;
      case ReaderTheme.sepia:
        return AppColors.sepiaText;
      case ReaderTheme.dark:
        return _textDark;
    }
  }
  // lib/features/offline/presentation/screens/offline_reader_screen.dart (Part 2)
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _bgColor;
    final textPrimary = _textColor;
    final secondary = _globalReaderTheme == ReaderTheme.sepia
        ? AppColors.sepiaText.withValues(alpha: 0.7)
        : (isDark
            ? const Color(0xFFB0B3B8)
            : const Color(0xFF65676B));

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const LoadingView());
    }
    if (_item == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
        ),
        body: ErrorView(message: l10n.offlineFileNotFound),
      );
    }

    final item = _item!;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Column(
            children: [
              Material(
                color: _brandGreen,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => context.pop(),
                            ),
                            Expanded(
                              child: Text(
                                item.subtitle ?? item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.offline_bolt,
                                size: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 2,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(child: ReaderWatermark()),
                    ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _brandGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.offline_bolt,
                                  size: 14,
                                  color: _brandGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.offline,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _brandGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: (22 * _globalFontScale).toDouble(),
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            color: textPrimary,
                          ),
                        ),
                        if (item.authorName != null ||
                            item.publicCode != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (item.authorName != null)
                                Text(
                                  item.authorName!,
                                  style: TextStyle(color: secondary),
                                ),
                              if (item.publicCode != null) ...[
                                if (item.authorName != null)
                                  Text(
                                    ' · ',
                                    style: TextStyle(color: secondary),
                                  ),
                                Text(
                                  item.publicCode!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _brandGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _copyCode(item.publicCode!),
                                  child: Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        SelectionContainer.disabled(
                          child: ReaderContent(
                            blocks: item.contentBlocks,
                            fontScale: _globalFontScale,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ReaderBottomBar(
                items: [
                  ReaderBottomBarItem(
                    icon: Icons.delete_outline,
                    tooltip: l10n.delete,
                    onTap: _deleteOffline,
                  ),
                  ReaderBottomBarItem(
                    icon: Icons.bookmark_border,
                    tooltip: l10n.bookmark,
                    onTap: () {},
                  ),
                  ReaderBottomBarItem(
                    icon: Icons.text_fields,
                    tooltip: l10n.fontSize,
                    onTap: _showFontSheet,
                  ),
                  ReaderBottomBarItem(
                    icon: Icons.palette_outlined,
                    tooltip: l10n.theme,
                    onTap: _showFontSheet,
                  ),
                  ReaderBottomBarItem(
                    icon: Icons.share_outlined,
                    tooltip: l10n.share,
                    onTap: _share,
                  ),
                ],
              ),
            ],
          ),
          if (_prev != null || _next != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_prev != null)
                    FloatingActionButton.small(
                      heroTag: 'offline_prev',
                      backgroundColor: _brandGreen,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        final targetId = _prev!.id;
                        context.pushReplacement(
                          '${RouteNames.offlineReader}/ep_$targetId',
                        );
                      },
                      child: const Icon(Icons.chevron_left),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_next != null)
                    FloatingActionButton.small(
                      heroTag: 'offline_next',
                      backgroundColor: _brandGreen,
                      foregroundColor: Colors.white,
                      onPressed: () {
                        final targetId = _next!.id;
                        context.pushReplacement(
                          '${RouteNames.offlineReader}/ep_$targetId',
                        );
                      },
                      child: const Icon(Icons.chevron_right),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
