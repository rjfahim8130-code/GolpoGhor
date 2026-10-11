// lib/core/services/media_compress_service.dart
// video_compress ^3.1.3 এর সঠিক API দিয়ে

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_compress/video_compress.dart';

class MediaCompressService {
  // ============================================================
  // ছবি কমপ্রেস
  // ============================================================

  Future<Uint8List> compressImageFile(
    File file, {
    int maxWidth = 1280,
    int quality = 75,
  }) async {
    final bytes = await file.readAsBytes();
    return compressBytes(bytes, maxWidth: maxWidth, quality: quality);
  }

  Future<Uint8List> compressBytes(
    Uint8List bytes, {
    int maxWidth = 1280,
    int quality = 75,
  }) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    img.Image out = decoded;
    if (out.width > maxWidth) {
      out = img.copyResize(
        out,
        width: maxWidth,
        interpolation: img.Interpolation.linear,
      );
    }

    final jpg = img.encodeJpg(out, quality: quality);
    return Uint8List.fromList(jpg);
  }

  Future<Uint8List> compressAvatar(File file) =>
      compressImageFile(file, maxWidth: 800, quality: 78);

  // ============================================================
  // ভিডিও কমপ্রেস
  // ============================================================

  Future<File?> compressVideoFile(
    File file, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool deleteOriginal = false,
  }) async {
    try {
      final sizeInMB = await file.length() / (1024 * 1024);
      if (sizeInMB < 10) {
        debugPrint('VIDEO_COMPRESS: skipped (${sizeInMB.toStringAsFixed(1)} MB)');
        return file;
      }

      debugPrint('VIDEO_COMPRESS: starting (${sizeInMB.toStringAsFixed(1)} MB)');

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: quality,
        deleteOrigin: deleteOriginal,
        includeAudio: true,
      );

      if (info == null || info.file == null) {
        debugPrint('VIDEO_COMPRESS: failed — returning original');
        return file;
      }

      final newSizeInMB = await info.file!.length() / (1024 * 1024);
      debugPrint(
        'VIDEO_COMPRESS: done — '
        '${sizeInMB.toStringAsFixed(1)} MB → '
        '${newSizeInMB.toStringAsFixed(1)} MB',
      );

      return info.file;
    } catch (e) {
      debugPrint('VIDEO_COMPRESS_ERROR: $e');
      return file;
    }
  }

  /// Progress subscription
  /// video_compress `compressProgress$` একটা `ObservableBuilder<double>` 
  /// — এটা `Stream` নয়, তাই `.subscribe()` দিয়ে listen করতে হয়
  Subscription? subscribeProgress(void Function(double) onProgress) {
    try {
      return VideoCompress.compressProgress$.subscribe((double progress) {
        // progress 0..100 আসে
        onProgress((progress / 100).clamp(0.0, 1.0));
      });
    } catch (e) {
      debugPrint('PROGRESS_SUBSCRIBE_ERROR: $e');
      return null;
    }
  }

  /// কমপ্রেসের আগে ভিডিওর তথ্য
  Future<MediaInfo?> getVideoInfo(String path) async {
    try {
      return await VideoCompress.getMediaInfo(path);
    } catch (_) {
      return null;
    }
  }

  /// কমপ্রেস বাতিল
  Future<void> cancelCompress() async {
    try {
      await VideoCompress.cancelCompression();
    } catch (_) {}
  }

  /// Temp files clear
  Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}
  }
}
