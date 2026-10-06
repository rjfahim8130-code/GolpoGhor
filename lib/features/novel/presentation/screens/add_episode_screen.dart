import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/theme/app_colors.dart';

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
  final _novelService = NovelService();
  final List<ContentBlockModel> _blocks = [];
  _Preset _preset = _Preset.body;
  bool _saving = false;

  File? _coverImage;
  String? _coverUrl;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _coverImage = File(picked.path);
      });
    }
  }

  ContentBlockModel _fromText(String text) {
    switch (_preset) {
      case _Preset.heading:
        return ContentBlockModel.textBlock(
          text,
          style: 'heading1',
          font: 'classic',
          weight: 'bold',
          align: 'center',
          size: 24,
        );
      case _Preset.emphasis:
        return ContentBlockModel.textBlock(
          text,
          style: 'emphasis',
          weight: 'bold',
          size: 17,
        );
      case _Preset.quote:
        return ContentBlockModel.textBlock(
          text,
          style: 'quote',
          italic: true,
        );
      case _Preset.body:
        return ContentBlockModel.textBlock(text, style: 'body');
    }
  }

  void _commit() {
    final t = _bodyCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _blocks.add(_fromText(t));
      _bodyCtrl.clear();
    });
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
    final left = _bodyCtrl.text.trim();
    if (left.isNotEmpty) blocks.add(_fromText(left));
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কিছু লেখা যোগ করুন')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // যদি কভার ইমেজ সিলেক্ট করা থাকে তবে তা আপলোড করা
      if (_coverImage != null) {
        _coverUrl = await _novelService.uploadImage(_coverImage!, 'novel_covers');
      }

      final ep = await _novelService.addEpisode(
        novelId: widget.novelId,
        title: title,
        contentBlocks: blocks,
        coverUrl: _coverUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পর্ব যোগ হয়েছে')),
      );
      context.go('/episode/${ep.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন পর্ব'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
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
              padding: const EdgeInsets.all(16),
              children: [
                // কভার ছবি আপলোড সেকশন
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      image: _coverImage != null
                          ? DecorationImage(
                              image: FileImage(_coverImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _coverImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 36, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('পর্বের কভার ছবি যোগ করুন (ঐচ্ছিক)', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
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
                if (_blocks.isNotEmpty) ...[
                  ...List.generate(_blocks.length, (i) {
                    final b = _blocks[i];
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
                          onPressed: () => setState(() => _blocks.removeAt(i)),
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
                  decoration: const InputDecoration(
                    hintText: 'পর্বের লেখা…',
                    border: OutlineInputBorder(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _commit,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('অংশ যোগ'),
                  ),
                ),
              ],
            ),
          ),
          Material(
            elevation: 6,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _chip('শিরোনাম', _Preset.heading),
                    _chip('স্বাভাবিক', _Preset.body),
                    _chip('গুরুত্বপূর্ণ', _Preset.emphasis),
                    _chip('উদ্ধৃতি', _Preset.quote),
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
      ),
    );
  }
}
