// lib/features/write/presentation/screens/add_episode_screen.dart
// সংশোধিত: localization

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

enum _Preset { heading, body, emphasis, quote }

class AddEpisodeScreen extends StatefulWidget {
  final String novelId;

  const AddEpisodeScreen({super.key, required this.novelId});

  @override
  State<AddEpisodeScreen> createState() => _AddEpisodeScreenState();
}

class _AddEpisodeScreenState extends State<AddEpisodeScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _episodeService = EpisodeService();
  final _storage = R2StorageService();
  final _picker = ImagePicker();

  final List<ContentBlockModel> _blocks = [];
  _Preset _preset = _Preset.body;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  ContentBlockModel _fromText(String text) {
    switch (_preset) {
      case _Preset.heading:
        return ContentBlockModel.heading(text);
      case _Preset.emphasis:
        return ContentBlockModel.emphasis(text);
      case _Preset.quote:
        return ContentBlockModel.quote(text);
      case _Preset.body:
        return ContentBlockModel.body(text);
    }
  }

  void _commitBody() {
    final t = _bodyCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _blocks.add(_fromText(t));
      _bodyCtrl.clear();
    });
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _loading = true);
    try {
      _commitBody();
      final url = await _storage.uploadImage(
        file: File(x.path),
        folder: 'episodes',
      );
      setState(() => _blocks.add(ContentBlockModel.imageBlock(url)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পর্বের শিরোনাম লিখুন')),
      );
      return;
    }

    final blocks = List<ContentBlockModel>.from(_blocks);
    final leftover = _bodyCtrl.text.trim();
    if (leftover.isNotEmpty) blocks.add(_fromText(leftover));

    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কিছু লেখা যোগ করুন')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ep = await _episodeService.addEpisode(
        novelId: widget.novelId,
        title: title,
        contentBlocks: blocks,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পর্ব যোগ হয়েছে')),
      );
      context.go('${RouteNames.episode}/${ep.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addEpisode),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(
              l10n.publish,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'পর্বের শিরোনাম',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 12),

                if (_blocks.isNotEmpty) ...[
                  ...List.generate(_blocks.length, (i) {
                    final b = _blocks[i];
                    if (b.isImage) {
                      return Card(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: b.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: b.imageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image),
                            ),
                          ),
                          title: const Text('ছবি'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _blocks.removeAt(i)),
                          ),
                        ),
                      );
                    }
                    return Card(
                      child: ListTile(
                        title: Text(
                          b.text ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(b.style),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => _blocks.removeAt(i)),
                        ),
                      ),
                    );
                  }),
                  const Divider(),
                ],

                TextField(
                  controller: _bodyCtrl,
                  maxLines: 10,
                  minLines: 5,
                  decoration: InputDecoration(
                    hintText: _hintForPreset(),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkSurface : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _commitBody,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('অংশ যোগ'),
                  ),
                ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _chip('শিরোনাম', _Preset.heading),
                    _chip('স্বাভাবিক', _Preset.body),
                    _chip('গুরুত্বপূর্ণ', _Preset.emphasis),
                    _chip('উদ্ধৃতি', _Preset.quote),
                    const SizedBox(width: 4),
                    ActionChip(
                      avatar: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined, size: 18),
                      label: const Text('ছবি'),
                      onPressed: _loading ? null : _pickImage,
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

  Widget _chip(String label, _Preset p) {
    final selected = _preset == p;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _preset = p),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  String _hintForPreset() {
    switch (_preset) {
      case _Preset.heading:
        return 'শিরোনাম…';
      case _Preset.emphasis:
        return 'গুরুত্বপূর্ণ…';
      case _Preset.quote:
        return 'উদ্ধৃতি…';
      case _Preset.body:
        return 'পর্বের লেখা…';
    }
  }
}
