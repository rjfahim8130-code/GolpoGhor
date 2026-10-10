import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/video_constants.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';

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
        SnackBar(content: Text('ভিডিও বেছে নিতে সমস্যা: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asDraft ? 'খসড়া সেভ হয়েছে' : 'ভিডিও প্রকাশিত হয়েছে'),
        ),
      );
      if (asDraft) {
        context.pop();
      } else {
        context.go('/videos');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('আপলোড ব্যর্থ: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
  
  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন ভিডিও'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _uploading ? null : () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _uploading || _checking
                ? null
                : () => _publish(asDraft: true),
            child: const Text('খসড়া'),
          ),
          TextButton(
            onPressed: _uploading || _checking
                ? null
                : () => _publish(asDraft: false),
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
          // প্রিভিউ / পিকার
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
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_durationSec সে. / ১৫ মিনিট',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: _checking
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.video_library_outlined,
                                  size: 48,
                                  color: Colors.white70,
                                ),
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

          // শিরোনাম
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'শিরোনাম (ঐচ্ছিক)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // বিবরণ
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'বিবরণ / ক্যাপশন',
              border: OutlineInputBorder(),
            ),
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
          const SizedBox(height: 8),

          // সিরিজ switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text('পর্বভিত্তিক সিরিজ'),
            subtitle: Text(
              'একাধিক পর্ব একই সিরিজে সংযুক্ত হবে',
              style: TextStyle(fontSize: 12, color: secondary),
            ),
            value: _asSeries,
            onChanged: _uploading
                ? null
                : (v) => setState(() {
                      _asSeries = v;
                      if (v && _seriesId == null) {
                        _seriesId = const Uuid().v4();
                      }
                    }),
          ),

          if (_asSeries) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _seriesTitleCtrl,
              decoration: const InputDecoration(
                labelText: 'সিরিজের নাম',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'পর্ব নম্বর',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],

          // আপলোড প্রোগ্রেস
          if (_uploading) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'R2-তে আপলোড হচ্ছে… অনুগ্রহ করে অপেক্ষা করুন',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: secondary),
            ),
          ],
        ],
      ),
    );
  }
}
