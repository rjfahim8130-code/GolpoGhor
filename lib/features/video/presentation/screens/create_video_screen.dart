// lib/features/video/presentation/screens/create_video_screen.dart (Part 1)
// video_compress ^3.1.3 — subscribe API + ভিডিও ক্যাটাগরি সিস্টেম যুক্ত

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/constants/video_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/media_compress_service.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../routing/route_names.dart';

class CreateVideoScreen extends ConsumerStatefulWidget {
  const CreateVideoScreen({super.key});

  @override
  ConsumerState<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends ConsumerState<CreateVideoScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF242526);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _seriesTitleCtrl = TextEditingController();
  final _partCtrl = TextEditingController(text: '1');

  final _picker = ImagePicker();
  final _videoService = VideoService();
  final _storage = R2StorageService();
  final _compress = MediaCompressService();

  File? _file;
  int _durationSec = 0;
  bool _checking = false;
  bool _uploading = false;
  bool _compressing = false;
  bool _asSeries = false;
  String? _seriesId;

  String? _category;
  String? _categoryGroup;

  double _compressProgress = 0;
  Subscription? _progressSub;

  VideoPlayerController? _preview;

  @override
  void dispose() {
    _progressSub?.unsubscribe();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    _seriesTitleCtrl.dispose();
    _partCtrl.dispose();
    _preview?.dispose();
    super.dispose();
  }

  String _translateError(BuildContext context, Object e) {
    final raw = e.toString();
    final key = raw.replaceAll('Exception: ', '').trim();
    final l10n = context.l10n;
    return l10n.t(key);
  }

  Future<void> _pick() async {
    final l10n = context.l10n;
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
          SnackBar(content: Text(l10n.videoTooLong)),
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
        SnackBar(content: Text(_translateError(context, e))),
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
    final l10n = context.l10n;
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pickVideoFirst)),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _compressing = false;
      _compressProgress = 0;
    });

    try {
      setState(() => _compressing = true);

      _progressSub?.unsubscribe();
      _progressSub = _compress.subscribeProgress((p) {
        if (mounted) setState(() => _compressProgress = p);
      });

      final compressed = await _compress.compressVideoFile(_file!);
      final finalFile = compressed ?? _file!;

      _progressSub?.unsubscribe();
      _progressSub = null;

      if (mounted) setState(() => _compressing = false);

      final bytes = await finalFile.readAsBytes();
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
        if (seriesTitle.isEmpty) seriesTitle = l10n.series;
        seriesId ??= const Uuid().v4();
        part = int.tryParse(_partCtrl.text.trim()) ?? 1;
      }

      await _videoService.createVideo(
        videoUrl: url,
        durationSeconds: _durationSec,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        tags: _parseTags(_tagsCtrl.text),
        seriesId: seriesId,
        seriesTitle: seriesTitle,
        partNumber: part,
        isDraft: asDraft,
      );

      await _compress.deleteAllCache();

      if (!mounted) return;
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
        SnackBar(content: Text(_translateError(context, e))),
      );
    } finally {
      _progressSub?.unsubscribe();
      _progressSub = null;
      if (mounted) {
        setState(() {
          _uploading = false;
          _compressing = false;
        });
      }
    }
  }
  // lib/features/video/presentation/screens/create_video_screen.dart (Part 2)
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final cardBg = isDark ? _cardDark : _cardLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _brandGreen, width: 1.5),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.newVideo),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _uploading ? null : () => context.pop(),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: secondary),
            onPressed:
                _uploading || _checking ? null : () => _publish(asDraft: true),
            child: Text(l10n.draft),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _brandGreen),
            onPressed: _uploading || _checking
                ? null
                : () => _publish(asDraft: false),
            child: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _brandGreen,
                    ),
                  )
                : Text(
                    l10n.publish,
                    style: const TextStyle(
                      color: _brandGreen,
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
                color: const Color(0xFF050505),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
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
                              '$_durationSec ${l10n.durationOfMax}',
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
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.video_library_outlined,
                                  size: 48,
                                  color: Colors.white70,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.pickFromGallery,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (_compressing) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _brandGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _brandGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${l10n.compressingVideo} ${(_compressProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 13, color: primaryText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _compressProgress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: _brandGreen.withValues(alpha: 0.15),
                    color: _brandGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              labelText: '${l10n.title} (${l10n.optional})',
              labelStyle: TextStyle(color: secondary),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              labelText: l10n.description,
              labelStyle: TextStyle(color: secondary),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.optionalCategory,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _categoryGroup,
            dropdownColor: cardBg,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              labelText: l10n.selectGroup,
              labelStyle: TextStyle(color: secondary),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
              isDense: true,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.noCategory),
              ),
              ...CategoryCatalog.videoGroups.map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(l10n.t(g)),
                ),
              ),
            ],
            onChanged: (v) => setState(() {
              _categoryGroup = v;
              _category = null;
            }),
          ),
          if (_categoryGroup != null) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              value: _category,
              dropdownColor: cardBg,
              style: TextStyle(color: primaryText),
              decoration: InputDecoration(
                labelText: l10n.selectSubcategory,
                labelStyle: TextStyle(color: secondary),
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: focusedBorder,
                isDense: true,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.noCategory),
                ),
                ...CategoryCatalog.videoSubsOf(_categoryGroup!).map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(l10n.t(e.key)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
          ],
          if (_category != null || _categoryGroup != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _brandGreen),
              onPressed: () => setState(() {
                _category = null;
                _categoryGroup = null;
              }),
              child: Text(l10n.clearCategory),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsCtrl,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              labelText: l10n.tagsHint,
              labelStyle: TextStyle(color: secondary),
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: _brandGreen,
            title: Text(l10n.seriesMode, style: TextStyle(color: primaryText)),
            subtitle: Text(
              l10n.seriesModeDesc,
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
              style: TextStyle(color: primaryText),
              decoration: InputDecoration(
                labelText: l10n.seriesName,
                labelStyle: TextStyle(color: secondary),
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: focusedBorder,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _partCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: primaryText),
              decoration: InputDecoration(
                labelText: l10n.partNumber,
                labelStyle: TextStyle(color: secondary),
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: focusedBorder,
                isDense: true,
              ),
            ),
          ],
          if (_uploading && !_compressing) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(color: _brandGreen),
            const SizedBox(height: 8),
            Text(
              l10n.uploadingPleaseWait,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: secondary),
            ),
          ],
        ],
      ),
    );
  }
}
