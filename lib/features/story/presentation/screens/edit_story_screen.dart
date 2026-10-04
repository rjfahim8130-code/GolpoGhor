import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';

enum _WritePreset { heading, body, emphasis, quote }

class EditStoryScreen extends StatefulWidget {
  final String storyId;

  const EditStoryScreen({super.key, required this.storyId});

  @override
  State<EditStoryScreen> createState() => _EditStoryScreenState();
}

class _EditStoryScreenState extends State<EditStoryScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _storyService = StoryService();
  final _storage = R2StorageService();
  final _picker = ImagePicker();

  _WritePreset _preset = _WritePreset.body;
  String? _category;
  String? _coverUrl;
  final List<ContentBlockModel> _blocks = [];
  bool _loading = true;
  bool _saving = false;
  bool _isDraft = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final story = await _storyService.getById(widget.storyId);
      if (story == null) {
        setState(() {
          _error = 'গল্প পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }
      _titleCtrl.text = story.title;
      _descCtrl.text = story.description;
      _category = story.category;
      _coverUrl = story.coverUrl;
      _isDraft = story.isDraft;
      _blocks
        ..clear()
        ..addAll(story.contentBlocks);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'লোড সমস্যা';
        _loading = false;
      });
    }
  }

  ContentBlockModel _blockFromText(String text) {
    switch (_preset) {
      case _WritePreset.heading:
        return ContentBlockModel.textBlock(
          text,
          style: 'heading1',
          font: 'classic',
          weight: 'bold',
          align: 'center',
          size: 26,
        );
      case _WritePreset.emphasis:
        return ContentBlockModel.textBlock(
          text,
          style: 'emphasis',
          font: 'modern',
          weight: 'bold',
          size: 17,
        );
      case _WritePreset.quote:
        return ContentBlockModel.textBlock(
          text,
          style: 'quote',
          font: 'classic',
          italic: true,
          size: 16,
        );
      case _WritePreset.body:
        return ContentBlockModel.textBlock(
          text,
          style: 'body',
          font: 'modern',
          size: 16,
        );
    }
  }

  void _commitBody() {
    final t = _bodyCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _blocks.add(_blockFromText(t));
      _bodyCtrl.clear();
    });
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (x == null) return;
    setState(() => _saving = true);
    try {
      _commitBody();
      final url = await _storage.uploadImage(file: File(x.path));
      setState(() {
        _blocks.add(ContentBlockModel.imageBlock(url));
        _coverUrl ??= url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save({required bool asDraft}) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শিরোনাম লিখুন')),
      );
      return;
    }

    final blocks = List<ContentBlockModel>.from(_blocks);
    final left = _bodyCtrl.text.trim();
    if (left.isNotEmpty) blocks.add(_blockFromText(left));

    setState(() => _saving = true);
    try {
      final story = await _storyService.updateStory(
        storyId: widget.storyId,
        title: title,
        description: _descCtrl.text.trim(),
        category: _category,
        coverUrl: _coverUrl,
        contentBlocks: blocks,
        isDraft: asDraft,
        isPublished: !asDraft,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asDraft ? 'খসড়া সেভ' : 'আপডেট ও প্রকাশিত'),
        ),
      );
      if (asDraft) {
        context.pop();
      } else {
        context.go('/story/${story.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('গল্প মুছবেন?'),
        content: const Text('এটি পুনরুদ্ধার করা যাবে না।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _storyService.deleteStory(widget.storyId);
      if (!mounted) return;
      context.go('/my-works');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('আবার')),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDraft ? 'খসড়া এডিট' : 'গল্প এডিট'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _saving ? null : _delete,
          ),
          TextButton(
            onPressed: _saving ? null : () => _save(asDraft: true),
            child: const Text('খসড়া'),
          ),
          TextButton(
            onPressed: _saving ? null : () => _save(asDraft: false),
            child: const Text(
              'প্রকাশ',
              style: TextStyle(
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
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
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'বিবরণ',
                    border: InputBorder.none,
                  ),
                ),
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
                if (_blocks.isNotEmpty) ...[
                  const Text(
                    'কনটেন্ট ব্লক',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_blocks.length, (i) {
                    final b = _blocks[i];
                    if (b.type == 'image') {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.image),
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
                          onPressed: () => setState(() => _blocks.removeAt(i)),
                        ),
                      ),
                    );
                  }),
                  const Divider(),
                ],
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 6,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: 'নতুন অংশ লিখুন…',
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
                    _chip('শিরোনাম', _WritePreset.heading),
                    _chip('স্বাভাবিক', _WritePreset.body),
                    _chip('গুরুত্বপূর্ণ', _WritePreset.emphasis),
                    _chip('উদ্ধৃতি', _WritePreset.quote),
                    ActionChip(
                      avatar: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined, size: 18),
                      label: const Text('ছবি'),
                      onPressed: _saving ? null : _pickImage,
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

  Widget _chip(String label, _WritePreset p) {
    final selected = _preset == p;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _preset = p),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
