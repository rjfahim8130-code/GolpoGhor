import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

enum WriteKind { story, novel }

enum _Preset { heading, body, emphasis, quote }

/// গল্প ও উপন্যাস — একই স্ক্রিন
/// পার্থক্য:
/// - গল্প: content_blocks সহ সেভ হয়
/// - উপন্যাস: শুধু মেটাডেটা সেভ → পর্ব যোগ আলাদা স্ক্রিনে
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

  // ---------- Blocks ----------

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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('কভার: $e')));
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ছবি: $e')));
      }
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

  // ---------- Save ----------

  Future<void> _save({required bool asDraft}) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শিরোনাম লিখুন')),
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('সেভ ব্যর্থ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveStory({
    required String title,
    required bool asDraft,
  }) async {
    // শেষ লাইন যোগ
    final blocks = List<ContentBlockModel>.from(_blocks);
    final leftover = _bodyCtrl.text.trim();
    if (leftover.isNotEmpty) blocks.add(_fromText(leftover));

    if (blocks.isEmpty && !asDraft) {
      throw Exception('কিছু লেখা যোগ করুন');
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
      // নতুন উপন্যাস তৈরি হলে সোজা details-এ যাবে (সেখানে পর্ব যোগ করা যাবে)
      context.go('${RouteNames.novel}/${n.id}');
    }
  }
  
  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
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
              ? (_isStory ? 'গল্প সম্পাদনা' : 'উপন্যাস সম্পাদনা')
              : (_isStory ? 'নতুন গল্প' : 'নতুন উপন্যাস'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => _save(asDraft: true),
            child: const Text('খসড়া'),
          ),
          TextButton(
            onPressed: _loading ? null : () => _save(asDraft: false),
            child: Text(
              _isStory ? 'প্রকাশ' : 'তৈরি',
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
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                                SizedBox(height: 8),
                                Text('কভার ছবি (ঐচ্ছিক)'),
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
                  decoration: const InputDecoration(
                    hintText: 'শিরোনাম',
                    border: InputBorder.none,
                  ),
                ),

                // বিবরণ
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'সংক্ষিপ্ত বিবরণ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // ক্যাটাগরি
                DropdownButtonFormField<String>(
                  value: _category != null &&
                          AppConstants.categories.contains(_category)
                      ? _category
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'ক্যাটাগরি',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: AppConstants.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),

                // ট্যাগ
                TextField(
                  controller: _tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ট্যাগ (স্পেস বা কমা দিয়ে)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // গল্প হলে: content blocks
                if (_isStory) ...[
                  if (_blocks.isNotEmpty) ...[
                    const Text(
                      'যোগ করা অংশ',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
                            title: const Text('ছবি'),
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
                      hintText: _hintForPreset(),
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
                      label: const Text('অংশ যোগ'),
                    ),
                  ),
                  Text(
                    'টিপস: স্বাভাবিক লিখুন; মাঝে শিরোনাম বা গুরুত্বপূর্ণ অংশ আলাদা করুন।',
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
                            'উপন্যাস তৈরি হলে পরের স্ক্রিনে পর্ব যোগ করা যাবে।',
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
        return 'বড় শিরোনাম লিখুন…';
      case _Preset.emphasis:
        return 'গুরুত্বপূর্ণ বাক্য…';
      case _Preset.quote:
        return 'উদ্ধৃতি বা মনের কথা…';
      case _Preset.body:
        return 'গল্প লিখুন… (পরে "অংশ যোগ করুন")';
    }
  }
}
