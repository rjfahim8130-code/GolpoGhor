// lib/features/video/presentation/screens/create_video_screen.dart
// সংশোধিত: localization, RouteNames ব্যবহার

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/video_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

class CreateVideoScreen extends ConsumerStatefulWidget {
  const CreateVideoScreen({super.key});

  @override
  ConsumerState<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends ConsumerState<CreateVideoScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _seriesTitleCtrl = TextEditingController();
  final _partCtrl = TextEditingController(text: '1');

  final _picker = ImagePicker();
  final _videoService = VideoService();
  final _storage = R2StorageService();

  File? _file;
  int _durationSec = 0;
  bool _checking = false;
  bool _uploading = false;
  bool _asSeries = false;
  String? _seriesId;

  VideoPlayerController? _preview;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    _seriesTitleCtrl.dispose();
    _partCtrl.dispose();
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _checking = true);
    try {
      final x = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 15),
      );
      if (x == null) {
        if (mounted) setState(() => _checking = false);
        return;
      }

      final file = File(x.path);
      await _preview?.dispose();
      final ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      final sec = ctrl.value.duration.inSeconds;

      final max = ref.read(videoMaxDurationProvider).maybeWhen(
            data: (v) => v,
            orElse: () => VideoConstants.maxDurationSeconds,
          );

      if (sec > max) {
        await ctrl.dispose();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(VideoConstants.maxDurationMessage)),
        );
        setState(() {
          _file = null;
          _durationSec = 0;
          _preview = null;
          _checking = false;
        });
        return;
      }

      setState(() {
        _file = file;
        _durationSec = sec;
        _preview = ctrl;
        _checking = false;
      });

      await ctrl.setLooping(true);
      await ctrl.setVolume(0);
      await ctrl.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[\s,，#]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _publish({bool asDraft = false}) async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আগে একটি ভিডিও বেছে নিন')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final bytes = await _file!.readAsBytes();
      final url = await _storage.uploadVideoBytes(
        bytes: bytes,
        contentType: 'video/mp4',
        folder: 'videos',
      );

      String? seriesId = _seriesId;
      String? seriesTitle;
      int part = 1;
      if (_asSeries) {
        seriesTitle = _seriesTitleCtrl.text.trim();
        if (seriesTitle.isEmpty) seriesTitle = 'সিরিজ';
        seriesId ??= const Uuid().v4();
        part = int.tryParse(_partCtrl.text.trim()) ?? 1;
      }

      await _videoService.createVideo(
        videoUrl: url,
        durationSeconds: _durationSec,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        tags: _parseTags(_tagsCtrl.text),
        seriesId: seriesId,
        seriesTitle: seriesTitle,
        partNumber: part,
        isDraft: asDraft,
      );

      if (!mounted) return;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asDraft ? l10n.draft : l10n.publish),
        ),
      );
      if (asDraft) {
        context.pop();
      } else {
        context.go(RouteNames.videos);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
