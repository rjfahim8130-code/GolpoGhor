// lib/features/video/presentation/screens/edit_video_screen.dart (Part 1)
// সংশোধিত: localization এবং ক্যাটাগরি সিলেকশন (মেইন গ্রুপ → সাব) যুক্ত

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/video_model.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class EditVideoScreen extends StatefulWidget {
  final String videoId;

  const EditVideoScreen({super.key, required this.videoId});

  @override
  State<EditVideoScreen> createState() => _EditVideoScreenState();
}

class _EditVideoScreenState extends State<EditVideoScreen> {
  final _service = VideoService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  VideoModel? _video;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _category;      // সাব key — DB তে যাবে
  String? _categoryGroup; // শুধু UI এর জন্য মেইন গ্রুপ

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  /// Exception থেকে key বের করে l10n দিয়ে translate
  String _translateError(BuildContext context, Object e) {
    final raw = e.toString();
    final key = raw.replaceAll('Exception: ', '').trim();
    final l10n = context.l10n;
    return l10n.t(key);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final v = await _service.getById(widget.videoId);
      if (v == null) {
        if (!mounted) return;
        setState(() {
          _error = 'videoNotFound';
          _loading = false;
        });
        return;
      }
      _titleCtrl.text = v.title;
      _descCtrl.text = v.description;
      _tagsCtrl.text = v.tags.join(' ');
      
      // ক্যাটাগরি ও গ্রুপ সেটআপ
      _category = CategoryCatalog.normalize(v.category);
      _categoryGroup = _category == null
          ? null
          : CategoryCatalog.groupOfSub(_category!, video: true);

      if (mounted) {
        setState(() {
          _video = v;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'loadFailed';
        _loading = false;
      });
    }
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[\s,，#]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.updateVideo(
        videoId: widget.videoId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category, // ক্যাটাগরি সাব কি আপডেট
        tags: _parseTags(_tagsCtrl.text),
      );
      if (!mounted) return;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.save} ✓')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteVideoConfirm),
        content: Text(l10n.cannotUndoLong),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteVideo(widget.videoId);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    }
  }
  // lib/features/video/presentation/screens/edit_video_screen.dart (Part 2)

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.edit} (${l10n.video})'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(
                  message: l10n.t(_error!),
                  onRetry: _load,
                  retryLabel: l10n.retry,
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_video != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_video!.durationSeconds}s'
                                ' · ${TimeAgo.of(context, _video!.createdAt)}'
                                '${_video!.isSeries ? " · ${l10n.episodeLabel} ${_video!.partNumber}" : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.title,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---------- ক্যাটাগরি (মেইন গ্রুপ → সাব) ----------
                    Text(
                      l10n.optionalCategory,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _categoryGroup,
                      decoration: InputDecoration(
                        labelText: l10n.selectGroup,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.noCategory),
                        ),
                        ...CategoryCatalog.videoGroups.map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(l10n.t(g)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        _categoryGroup = v;
                        _category = null; // গ্রুপ বদলালে সাব রিসেট
                      }),
                    ),
                    if (_categoryGroup != null) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: l10n.selectSubcategory,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.noCategory),
                          ),
                          ...CategoryCatalog.videoSubsOf(_categoryGroup!).map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(l10n.t(e.key)),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ],
                    if (_category != null || _categoryGroup != null)
                      TextButton(
                        onPressed: () => setState(() {
                          _category = null;
                          _categoryGroup = null;
                        }),
                        child: Text(l10n.clearCategory),
                      ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _tagsCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.tags,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    OutlinedButton.icon(
                      onPressed: _saving ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text('${l10n.video} ${l10n.delete}'),
                    ),
                  ],
                ),
    );
  }
}
