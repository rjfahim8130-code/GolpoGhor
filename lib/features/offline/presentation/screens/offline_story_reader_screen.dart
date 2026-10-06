import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
  OfflineStoryItem? _item;
  bool _loading = true;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final item = await _service.getStory(widget.storyId);
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_item == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('অফলাইন ফাইল পাওয়া যায়নি')),
      );
    }

    final item = _item!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              setState(() {
                _fontScale = _fontScale >= 1.4 ? 1.0 : _fontScale + 0.15;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ReaderWatermark()),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'অফলাইন',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 24 * _fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.authorName != null || item.publicCode != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item.authorName != null)
                      Text(
                        item.authorName!,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    if (item.publicCode != null) ...[
                      if (item.authorName != null)
                        Text(
                          ' · ',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      Text(
                        item.publicCode!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'কোড কপি করুন',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.publicCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('কোড কপি হয়েছে')),
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
    );
  }
}
