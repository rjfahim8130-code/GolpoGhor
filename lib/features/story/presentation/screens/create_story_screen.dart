import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';

enum _WritePreset { heading, body, emphasis, quote }

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _storyService = StoryService();
  final _storage = R2StorageService();
  final _picker = ImagePicker();

  _WritePreset _preset = _WritePreset.body;
  String? _category;
  final List<ContentBlockModel> _blocks = [];
  String? _pendingImageUrl;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  ContentBlockModel _blockFromCurrentText(String text) {
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

  void _commitBodyText() {
    final t = _bodyCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _blocks.add(_blockFromCurrentText(t));
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
      // আগে বডি টেক্সট কমিট
      _commitBodyText();
      final url = await _storage.uploadImage(file: File(x.path));
      setState(() {
        _blocks.add(ContentBlockModel.imageBlock(url));
        _pendingImageUrl ??= url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি আপলোড: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removeBlock(int index) {
    setState(() => _blocks.removeAt(index));
  }

  Future<void> _save({required bool asDraft}) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('গল্পের নাম লিখুন')),
      );
      return;
    }

    // বাকি টেক্সট যোগ
    final leftover = _bodyCtrl.text.trim();
    final blocks = List<ContentBlockModel>.from(_blocks);
    if (leftover.isNotEmpty) {
      blocks.add(_blockFromCurrentText(leftover));
    }

    if (blocks.isEmpty && !asDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কিছু লেখা যোগ করুন')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final story = await _storyService.createStory(
        title: title,
        description: _descCtrl.text.trim(),
        category: _category,
        coverUrl: _pendingImageUrl,
        contentBlocks: blocks,
        isDraft: asDraft,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asDraft ? 'খসড়া সেভ হয়েছে' : 'গল্প প্রকাশিত হয়েছে'),
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
          SnackBar(content: Text('সেভ ব্যর্থ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন গল্প'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(asDraft: true),
            child: const Text('খসড়া'),
          ),
          TextButton(
            onPressed: _saving ? null : () => _save(asDraft: false),
            child: Text(
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
                    hintText: 'গল্পের শিরোনাম',
                    border: InputBorder.none,
                  ),
                ),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'সংক্ষিপ্ত বিবরণ (ঐচ্ছিক)',
                    border: InputBorder.none,
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'ক্যাটাগরি',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: AppConstants.categories
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),
                if (_blocks.isNotEmpty) ...[
                  const Text(
                    'যোগ করা অংশ',
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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _commitBodyText,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('অংশ যোগ করুন'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'টিপস: স্বাভাবিক লিখুন; মাঝে শিরোনাম বা গুরুত্বপূর্ণ চাপুন।',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // টুলবার
          Material(
            elevation: 8,
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _PresetChip(
                      label: 'শিরোনাম',
                      selected: _preset == _WritePreset.heading,
                      onTap: () =>
                          setState(() => _preset = _WritePreset.heading),
                    ),
                    _PresetChip(
                      label: 'স্বাভাবিক',
                      selected: _preset == _WritePreset.body,
                      onTap: () => setState(() => _preset = _WritePreset.body),
                    ),
                    _PresetChip(
                      label: 'গুরুত্বপূর্ণ',
                      selected: _preset == _WritePreset.emphasis,
                      onTap: () =>
                          setState(() => _preset = _WritePreset.emphasis),
                    ),
                    _PresetChip(
                      label: 'উদ্ধৃতি',
                      selected: _preset == _WritePreset.quote,
                      onTap: () =>
                          setState(() => _preset = _WritePreset.quote),
                    ),
                    const SizedBox(width: 4),
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

  String _hintForPreset() {
    switch (_preset) {
      case _WritePreset.heading:
        return 'বড় শিরোনাম লিখুন…';
      case _WritePreset.emphasis:
        return 'গুরুত্বপূর্ণ বাক্য…';
      case _WritePreset.quote:
        return 'উদ্ধৃতি বা মনের কথা…';
      case _WritePreset.body:
        return 'গল্প লিখুন… (পরে “অংশ যোগ করুন”)';
    }
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
