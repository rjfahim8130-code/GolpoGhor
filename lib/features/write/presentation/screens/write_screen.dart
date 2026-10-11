// lib/features/write/presentation/screens/write_screen.dart
// সংশোধিত: localization

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

enum WriteKind { story, novel }

enum _Preset { heading, body, emphasis, quote }

class WriteScreen extends StatefulWidget {
  final WriteKind kind;
  final String? editId;

  const WriteScreen({
    super.key,
    required this.kind,
    this.editId,
  });

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _storyService = StoryService();
  final _novelService = NovelService();
  final _storage = R2StorageService();
  final _picker = ImagePicker();

  final List<ContentBlockModel> _blocks = [];
  _Preset _preset = _Preset.body;
  String? _category;
  String? _coverUrl;
  bool _loading = false;
  bool _init = true;
  bool _isDraft = false;

  bool get _isStory => widget.kind == WriteKind.story;
  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    } else {
      _init = false;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _init = true);
    try {
      if (_isStory) {
        final s = await _storyService.getById(widget.editId!);
        if (s != null) {
          _titleCtrl.text = s.title;
          _descCtrl.text = s.description;
          _tagsCtrl.text = s.tags.join(' ');
          _category = s.category;
          _coverUrl = s.coverUrl;
          _isDraft = s.isDraft;
          _blocks
            ..clear()
            ..addAll(s.contentBlocks);
        }
      } else {
        final n = await _novelService.getById(widget.editId!);
        if (n != null) {
          _titleCtrl.text = n.title;
          _descCtrl.text = n.description;
          _tagsCtrl.text = n.tags.join(' ');
          _category = n.category;
          _coverUrl = n.coverUrl;
          _isDraft = n.isDraft;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _init = false);
  }

  /// Exception থেকে key বের করে l10n দিয়ে translate
  String _translateError(BuildContext context, Object e) {
    final raw = e.toString();
    final key = raw.replaceAll('Exception: ', '').trim();
    final l10n = context.l10n;
    return l10n.t(key);
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

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _loading = true);
    try {
      final url = await _storage.uploadCover(File(x.path));
      setState(() => _coverUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        folder: 'stories',
      );
      setState(() => _blocks.add(ContentBlockModel.imageBlock(url)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _removeBlock(int index) {
    setState(() => _blocks.removeAt(index));
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[\s,，#]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save({required bool asDraft}) async {
    final l10n = context.l10n;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterTitle)),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isStory) {
        await _saveStory(title: title, asDraft: asDraft);
      } else {
        await _saveNovel(title: title, asDraft: asDraft);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveStory({
    required String title,
    required bool asDraft,
  }) async {
    final l10n = context.l10n;
    final blocks = List<ContentBlockModel>.from(_blocks);
    final leftover = _bodyCtrl.text.trim();
    if (leftover.isNotEmpty) blocks.add(_fromText(leftover));

    if (blocks.isEmpty && !asDraft) {
      throw Exception(l10n.addSomeText);
    }

    if (_isEdit) {
      final s = await _storyService.updateStory(
        storyId: widget.editId!,
        title: title,
        description: _descCtrl.text.trim(),
        category: _category,
        tags: _parseTags(_tagsCtrl.text),
        coverUrl: _coverUrl,
        contentBlocks: blocks,
        isDraft: asDraft,
        isPublished: !asDraft,
      );
      if (!mounted) return;
      if (asDraft) {
        context.pop();
      } else {
        context.go('${RouteNames.story}/${s.id}');
      }
    } else {
      final s = await _storyService.createStory(
        title: title,
        description: _descCtrl.text.trim(),
        category: _category,
        tags: _parseTags(_tagsCtrl.text),
        coverUrl: _coverUrl,
        contentBlocks: blocks,
        isDraft: asDraft,
      );
      if (!mounted) return;
      if (asDraft) {
        context.pop();
      } else {
        context.go('${RouteNames.story}/${s.id}');
      }
    }
  }

  Future<void> _saveNovel({
    required String title,
    required bool asDraft,
  }) async {
    if (_isEdit) {
      final n = await _novelService.updateNovel(
        novelId: widget.editId!,
        title: title,
        description: _descCtrl.text.trim(),
        category: _category,
        tags: _parseTags(_tagsCtrl.text),
        coverUrl: _coverUrl,
        isDraft: asDraft,
        isPublished: !asDraft,
      );
      if (!mounted) return;
      context.go('${RouteNames.novel}/${n.id}');
    } else {
      final n = await _novelService.createNovel(
        title: title,
        description: _descCtrl.text.trim(),
        category: _category,
        tags: _parseTags(_tagsCtrl.text),
        coverUrl: _coverUrl,
        isDraft: asDraft,
      );
      if (!mounted) return;
      context.go('${RouteNames.novel}/${n.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_init) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? (_isStory ? l10n.editStory : l10n.editNovel)
              : (_isStory ? l10n.newStory : l10n.newNovel),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => _save(asDraft: true),
            child: Text(l10n.draft),
          ),
          TextButton(
            onPressed: _loading ? null : () => _save(asDraft: false),
            child: Text(
              _isStory ? l10n.publish : l10n.create,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // কভার
                GestureDetector(
                  onTap: _loading ? null : _pickCover,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      image: (_coverUrl != null && _coverUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(_coverUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (_coverUrl == null || _coverUrl!.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.coverImageOptional),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // শিরোনাম
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.title,
                    border: InputBorder.none,
                  ),
                ),

                // বিবরণ
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText: l10n.description,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // ক্যাটাগরি
                DropdownButtonFormField<String>(
                  value: _category != null &&
                          l10n.categoryList.contains(_category)
                      ? _category
                      : null,
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: l10n.categoryList
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),

                // ট্যাগ
                TextField(
                  controller: _tagsCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.tagsHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // গল্প হলে: content blocks
                if (_isStory) ...[
                  if (_blocks.isNotEmpty) ...[
                    Text(
                      l10n.addedParts,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
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
                            title: Text(l10n.image),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeBlock(i),
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
                            style: TextStyle(
                              fontWeight: b.style == 'heading1'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontStyle: b.style == 'quote'
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          subtitle: Text(b.style),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeBlock(i),
                          ),
                        ),
                      );
                    }),
                    const Divider(),
                  ],

                  // লেখার বক্স
                  TextField(
                    controller: _bodyCtrl,
                    maxLines: 8,
                    minLines: 4,
                    decoration: InputDecoration(
                      hintText: _hintForPreset(l10n),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade50,
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
                      label: Text(l10n.addPart),
                    ),
                  ),
                  Text(
                    l10n.writeTips,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],

                // উপন্যাস হলে: hint
                if (!_isStory)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.novelNextEpisodeHint,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // গল্প হলে নিচে টুলবার
          if (_isStory)
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
                      _chip(l10n.blockHeading, _Preset.heading),
                      _chip(l10n.blockBody, _Preset.body),
                      _chip(l10n.blockEmphasis, _Preset.emphasis),
                      _chip(l10n.blockQuote, _Preset.quote),
                      const SizedBox(width: 4),
                      ActionChip(
                        avatar: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image_outlined, size: 18),
                        label: Text(l10n.image),
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

  String _hintForPreset(AppLocalizations l10n) {
    switch (_preset) {
      case _Preset.heading:
        return l10n.hintHeading;
      case _Preset.emphasis:
        return l10n.hintEmphasis;
      case _Preset.quote:
        return l10n.hintQuote;
      case _Preset.body:
        return l10n.hintBody;
    }
  }
}
