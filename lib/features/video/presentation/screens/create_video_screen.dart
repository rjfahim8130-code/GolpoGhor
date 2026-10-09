import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/video_constants.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';

class CreateVideoScreen extends StatefulWidget {
  const CreateVideoScreen({super.key});

  @override
  State<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends State<CreateVideoScreen> {
  final _descCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
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
    _descCtrl.dispose();
    _titleCtrl.dispose();
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
        setState(() => _checking = false);
        return;
      }

      final file = File(x.path);
      await _preview?.dispose();
      final ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      final sec = ctrl.value.duration.inSeconds;

      final max = await _videoService.maxDurationSeconds();
      if (sec > max) {
        await ctrl.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(VideoConstants.maxDurationMessage)),
          );
        }
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
      setState(() => _checking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ভিডিও বেছে নিতে সমস্যা: $e')),
        );
      }
    }
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(RegExp(r'[\s,，#]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _publish() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আগে একটি ভিডিও বেছে নিন')),
      );
      return;
    }

    final enabled = await _videoService.isVideoFeatureEnabled();
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(VideoConstants.featureOffMessage)),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      // R2 — ভিডিও বাইট (আপাতত সরাসরি; পরে FFmpeg কমপ্রেস)
      final bytes = await _file!.readAsBytes();
      // R2StorageService এখন শুধু ইমেজ API — ভিডিওর জন্য put বাইনারি এক্সটেনশন
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

      final video = await _videoService.createVideo(
        videoUrl: url,
        durationSeconds: _durationSec,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        tags: _parseTags(_tagsCtrl.text),
        seriesId: seriesId,
        seriesTitle: seriesTitle,
        partNumber: part,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ভিডিও প্রকাশিত হয়েছে')),
      );
      context.go('/videos');
      // ফিড রিফ্রেশ: ইউজার পুল-টু-রিফ্রেশ করতে পারে
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('আপলোড ব্যর্থ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ভিডিও আপলোড'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _uploading || _checking ? null : _publish,
            child: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'প্রকাশ',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _checking || _uploading ? null : _pick,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _preview != null && _preview!.value.isInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: _preview!.value.aspectRatio == 0
                                ? 9 / 16
                                : _preview!.value.aspectRatio,
                            child: VideoPlayer(_preview!),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: Colors.black54,
                            child: Text(
                              '$_durationSec সেকেন্ড / সর্বোচ্চ ১৫ মিনিট',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: _checking
                          ? const CircularProgressIndicator()
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.video_library_outlined,
                                    size: 48, color: Colors.white70),
                                SizedBox(height: 8),
                                Text(
                                  'গ্যালারি থেকে ভিডিও বেছে নিন',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'শিরোনাম (ঐচ্ছিক)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'বিবরণ / ক্যাপশন',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsCtrl,
            decoration: const InputDecoration(
              labelText: 'ট্যাগ (স্পেস বা কমা দিয়ে)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('পর্বভিত্তিক সিরিজ'),
            value: _asSeries,
            onChanged: (v) => setState(() {
              _asSeries = v;
              if (v && _seriesId == null) {
                _seriesId = const Uuid().v4();
              }
            }),
          ),
          if (_asSeries) ...[
            TextField(
              controller: _seriesTitleCtrl,
              decoration: const InputDecoration(
                labelText: 'সিরিজের নাম',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'পর্ব নম্বর',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_uploading) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('R2-তে আপলোড হচ্ছে…', textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
