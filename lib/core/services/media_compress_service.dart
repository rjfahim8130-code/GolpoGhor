// lib/core/services/media_compress_service.dart
// ছবি + ভিডিও কমপ্রেস
// ছবি: image package | ভিডিও: video_compress

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_compress/video_compress.dart';

class MediaCompressService {
  // ═══════════════════════════════════════════════════════════
  // ছবি কমপ্রেস (image package দিয়ে)
  // ═══════════════════════════════════════════════════════════

  /// ছবি ফাইল → কমপ্রেসড Uint8List
  /// 
  /// - [maxWidth]: সর্বোচ্চ প্রস্থ (default 1280)
  /// - [quality]: JPEG quality 1-100 (default 75)
  /// 
  /// লক্ষ্য: ~100-200 KB সাইজ
  Future<Uint8List> compressImageFile(
    File file, {
    int maxWidth = 1280,
    int quality = 75,
  }) async {
    final bytes = await file.readAsBytes();
    return compressBytes(bytes, maxWidth: maxWidth, quality: quality);
  }

  /// Bytes → কমপ্রেসড bytes
  Future<Uint8List> compressBytes(
    Uint8List bytes, {
    int maxWidth = 1280,
    int quality = 75,
  }) async {
    try {
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
    } catch (e) {
      debugPrint('IMAGE_COMPRESS_ERROR: $e');
      return bytes;
    }
  }

  /// Avatar — ছোট (800 px, quality 78)
  Future<Uint8List> compressAvatar(File file) =>
      compressImageFile(file, maxWidth: 800, quality: 78);

  // ═══════════════════════════════════════════════════════════
  // ভিডিও কমপ্রেস (video_compress package দিয়ে)
  // ═══════════════════════════════════════════════════════════

  /// ভিডিও ফাইল → কমপ্রেসড File
  /// 
  /// - [quality]: VideoQuality.LowQuality / MediumQuality / 
  ///              HighQuality / VeryHighQuality
  /// - [deleteOriginal]: true হলে original ফাইল ডিলিট হবে
  /// 
  /// 10 MB-র নিচে হলে skip করবে (ছোট ভিডিও wasteful)
  /// Error হলে original ফাইল ফেরত দেয় (safe)
  Future<File?> compressVideoFile(
    File file, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool deleteOriginal = false,
  }) async {
    try {
      // ─── ১. ছোট ফাইল skip ───
      final sizeInMB = await file.length() / (1024 * 1024);
      if (sizeInMB < 10) {
        debugPrint(
          'VIDEO_COMPRESS: skipped (${sizeInMB.toStringAsFixed(1)} MB)',
        );
        return file;
      }

      debugPrint(
        'VIDEO_COMPRESS: starting (${sizeInMB.toStringAsFixed(1)} MB)',
      );

      // ─── ২. Compress ───
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: quality,
        deleteOrigin: deleteOriginal,
        includeAudio: true,
      );

      // ─── ৩. ফলাফল যাচাই ───
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

  /// কমপ্রেসের progress subscribe করে (0.0 .. 1.0)
  /// 
  /// ফেরত দেয় Subscription — caller `.unsubscribe()` করতে পারবে।
  /// 
  /// ব্যবহার:
  /// ```dart
  /// final sub = compress.subscribeProgress((p) {
  ///   setState(() => _progress = p);
  /// });
  /// // শেষে
  /// sub?.unsubscribe();
  /// ```
  Subscription? subscribeProgress(void Function(double) onProgress) {
    try {
      return VideoCompress.compressProgress$.subscribe(
        (double progress) {
          // progress আসে 0..100
          onProgress((progress / 100).clamp(0.0, 1.0));
        },
      );
    } catch (e) {
      debugPrint('PROGRESS_SUBSCRIBE_ERROR: $e');
      return null;
    }
  }

  /// কমপ্রেসের আগে ভিডিওর তথ্য (duration, size, resolution)
  Future<MediaInfo?> getVideoInfo(String path) async {
    try {
      return await VideoCompress.getMediaInfo(path);
    } catch (_) {
      return null;
    }
  }

  /// কমপ্রেস বাতিল (ইউজার চাইলে)
  Future<void> cancelCompress() async {
    try {
      await VideoCompress.cancelCompression();
    } catch (_) {}
  }

  /// Temp files clear (compress session শেষে)
  Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}
  }
}
