// lib/features/write/presentation/screens/write_screen.dart
// সংশোধিত: localization

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
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
            .showSnackBar(SnackBar(content: Text('$e')));
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
            .showSnackBar(SnackBar(content: Text('$e')));
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
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveStory({
    required String title,
    required bool asDraft,
  }) async {
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
      context.go('${RouteNames.novel}/${n.id}');
    }
  }
