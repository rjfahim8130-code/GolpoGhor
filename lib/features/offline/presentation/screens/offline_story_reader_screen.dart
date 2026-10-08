import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/ui_strings.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../story/presentation/widgets/reader_content.dart';
import '../../../story/presentation/widgets/reader_watermark.dart';

class OfflineStoryReaderScreen extends StatefulWidget {
  final String storyId;

  const OfflineStoryReaderScreen({super.key, required this.storyId});

  @override
  State<OfflineStoryReaderScreen> createState() =>
      _OfflineStoryReaderScreenState();
}

class _OfflineStoryReaderScreenState extends State<OfflineStoryReaderScreen> {
  final _service = OfflineService();
  final _scroll = ScrollController();

  OfflineStoryItem? _item;
  bool _loading = true;
  double _fontScale = 0.9;
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
    if (max <= 0) {
      setState(() => _progress = 0);
      return;
    }
    setState(() => _progress = (_scroll.offset / max).clamp(0.0, 1.0));
  }

  Future<void> _load() async {
    final item = await _service.getStory(widget.storyId);
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
                      UiStrings.fontSize,
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
                              _fontScale = (_fontScale - 0.08).clamp(0.55, 1.5);
                            });
                            setModal(() {});
                          },
                          icon: const Icon(Icons.text_decrease),
                        ),
                        Text('${(_fontScale * 100).round()}%'),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontScale = (_fontScale + 0.08).clamp(0.55, 1.5);
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
      '${item.title}\n\nগল্পঘরে অফলাইনে পড়ুন'
      '${code.isNotEmpty ? '\nকোড: $code' : ''}\n#গল্পঘর',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_item == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('অফলাইন ফাইল পাওয়া যায়নি')),
      );
    }

    final item = _item!;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ফিক্সড বেগুনি টপ বার (আগের ও মূল রিডার স্ক্রিনের মতো)
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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

          // মাঝের কনটেন্ট ও ওয়াটারমার্ক
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: ReaderWatermark()),
                ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 24 * _fontScale,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    if (item.authorName != null || item.publicCode != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (item.authorName != null)
                            Text(
                              item.authorName!,
                              style: TextStyle(color: textSecondary),
                            ),
                          if (item.publicCode != null) ...[
                            if (item.authorName != null)
                              Text(' · ', style: TextStyle(color: textSecondary)),
                            Text(
                              item.publicCode!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary.withValues(alpha: 0.9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'কোড কপি করুন',
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: item.publicCode!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('কোড কপি হয়েছে')),
                                );
                              },
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

          // ফিক্সড বেগুনি বটম বার (শুধু ফন্ট সাইজ এবং শেয়ার বাটন — কোনো লাইক/কমেন্ট বা রিপোর্ট নেই)
          Material(
            color: AppColors.primary,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PurpleBarBtn(
                      icon: Icons.text_fields,
                      label: UiStrings.fontSize,
                      onTap: _showFontSheet,
                    ),
                    _PurpleBarBtn(
                      icon: Icons.share_outlined,
                      label: UiStrings.share,
                      onTap: _share,
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
}

class _PurpleBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PurpleBarBtn({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
