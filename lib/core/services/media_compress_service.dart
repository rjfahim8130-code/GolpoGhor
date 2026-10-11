// lib/core/services/media_compress_service.dart
// ছবি + ভিডিও কমপ্রেস — দুটোই

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_compress/video_compress.dart';

class MediaCompressService {
  // ============================================================
  // ছবি কমপ্রেস
  // ============================================================

  /// JPEG ~100–200KB লক্ষ্য, max width 1280
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

  /// Avatar — একটু ছোট (৮০০ px)
  Future<Uint8List> compressAvatar(File file) =>
      compressImageFile(file, maxWidth: 800, quality: 78);

  // ============================================================
  // ভিডিও কমপ্রেস
  // ============================================================

  /// ভিডিও ফাইল কমপ্রেস করে নতুন File ফেরত দেয়
  ///
  /// - [quality]: LowQuality / MediumQuality / HighQuality / VeryHighQuality
  /// - [targetWidth]: সর্বোচ্চ প্রস্থ (auto = aspect ratio রাখে)
  /// - [deleteOriginal]: true হলে original ফাইল ডিলিট হবে
  ///
  /// Progress দেখতে চাইলে `getVideoProgress(file.path)` স্ট্রিম ব্যবহার করুন।
  Future<File?> compressVideoFile(
    File file, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool deleteOriginal = false,
  }) async {
    try {
      // যদি ফাইল আগেই ছোট হয় (১০ MB-র নিচে) — কমপ্রেস না
      final sizeInMB = await file.length() / (1024 * 1024);
      if (sizeInMB < 10) {
        debugPrint('VIDEO_COMPRESS: skipped (${sizeInMB.toStringAsFixed(1)} MB)');
        return file;
      }

      debugPrint(
        'VIDEO_COMPRESS: starting (${sizeInMB.toStringAsFixed(1)} MB)',
      );

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
      return file; // fail হলে original ফেরত
    }
  }

  /// প্রগ্রেস stream — UI-তে দেখানোর জন্য
  Stream<double> videoProgressStream(String path) {
    return VideoCompress.compressProgress$.map((progress) {
      // progress 0..100
      return (progress / 100).clamp(0.0, 1.0);
    });
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

  /// ছবি/ভিডিও কমপ্রেস শেষে temp files clear
  /// (app বন্ধ হলে এই ফাইল auto-ডিলিট হয়)
  Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}
  }
}
