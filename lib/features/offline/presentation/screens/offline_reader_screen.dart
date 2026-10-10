import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../reader/presentation/widgets/reader_content.dart';
import '../../../reader/presentation/widgets/reader_watermark.dart';

class OfflineReaderScreen extends StatefulWidget {
  final String itemId;

  const OfflineReaderScreen({super.key, required this.itemId});

  @override
  State<OfflineReaderScreen> createState() => _OfflineReaderScreenState();
}

class _OfflineReaderScreenState extends State<OfflineReaderScreen> {
  final _service = OfflineService();
  final _scroll = ScrollController();

  OfflineItem? _item;
  bool _loading = true;
  double _fontScale = AppConstants.defaultFontScale;
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
    final item = await _service.get(widget.itemId);
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  void _showFontSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'লেখার আকার',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale -
                                      AppConstants.fontScaleStep)
                                  .clamp(
                                AppConstants.minFontScale,
                                AppConstants.maxFontScale,
                              );
                            });
                            setModal(() {});
                          },
                          icon: const Icon(Icons.text_decrease),
                        ),
                        Text('${(_fontScale * 100).round()}%'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale +
                                      AppConstants.fontScaleStep)
                                  .clamp(
                                AppConstants.minFontScale,
                                AppConstants.maxFontScale,
                              );
                            });
                            setModal(() {});
                          },
                          icon: const Icon(Icons.text_increase),
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

  Future<void> _share() async {
    final item = _item;
    if (item == null) return;
    final code = item.publicCode ?? '';
    await Share.share(
      '${item.title}\n\nগল্পঘরে পড়ুন'
      '${code.isNotEmpty ? '\nকোড: $code' : ''}\n#গল্পঘর',
    );
  }

  Future<void> _deleteOffline() async {
    final item = _item;
    if (item == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('অফলাইন থেকে মুছবেন?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('কোড কপি হয়েছে')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) {
      return Scaffold(backgroundColor: bg, body: const LoadingView());
    }
    if (_item == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const ErrorView(message: 'অফলাইন ফাইল পাওয়া যায়নি'),
      );
    }

    final item = _item!;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // সবুজ টপ বার
          Material(
            color: AppColors.primary,
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

          // মূল
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: ReaderWatermark()),
                ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    // অফলাইন চিপ
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'অফলাইন মোড',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // শিরোনাম
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 22 * _fontScale,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),

                    // লেখক + কোড
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
                              Text(' · ',
                                  style: TextStyle(color: secondary)),
                            Text(
                              item.publicCode!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _copyCode(item.publicCode!),
                              child: const Icon(Icons.copy, size: 14),
                            ),
                          ],
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                    SelectionContainer.disabled(
                      child: ReaderContent(
                        blocks: item.contentBlocks,
                        fontScale: _fontScale,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // সবুজ নিচের বার
          Material(
            color: AppColors.primary,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _barBtn(
                      Icons.text_fields,
                      'ফন্ট',
                      _showFontSheet,
                    ),
                    _barBtn(
                      Icons.share_outlined,
                      'শেয়ার',
                      _share,
                    ),
                    _barBtn(
                      Icons.delete_outline,
                      'মুছুন',
                      _deleteOffline,
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

  Widget _barBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
