import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class CreateNovelScreen extends StatefulWidget {
  const CreateNovelScreen({super.key});

  @override
  State<CreateNovelScreen> createState() => _CreateNovelScreenState();
}

class _CreateNovelScreenState extends State<CreateNovelScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _novelService = NovelService();
  final _storage = R2StorageService();
  final _picker = ImagePicker();

  String? _category;
  String? _coverUrl;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _saving = true);
    try {
      final url = await _storage.uploadImage(
        file: File(x.path),
        folder: 'covers',
      );
      setState(() => _coverUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('কভার: $e')),
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
        const SnackBar(content: Text('উপন্যাসের নাম লিখুন')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final novel = await _novelService.createNovel(
        title: title,
        description: _descCtrl.text.trim(),
        category: _category,
        coverUrl: _coverUrl,
        isDraft: asDraft,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asDraft ? 'খসড়া সেভ' : 'উপন্যাস তৈরি হয়েছে'),
        ),
      );
      context.go('/novel/${novel.id}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন উপন্যাস'),
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
            child: const Text(
              'তৈরি',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _saving ? null : _pickCover,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                image: _coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _coverUrl == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40),
                          SizedBox(height: 8),
                          Text('কভার ছবি'),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'উপন্যাসের নাম',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'সংক্ষিপ্ত বিবরণ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'ক্যাটাগরি',
              border: OutlineInputBorder(),
            ),
            items: AppConstants.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
          ),
          if (_saving) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
