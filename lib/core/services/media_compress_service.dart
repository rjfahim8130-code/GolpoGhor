// lib/core/services/media_compress_service.dart
// ছবি + ভিডিও কমপ্রেস — video_compressor_plus দিয়ে

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_compressor_plus/video_compressor_plus.dart';

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
  // ভিডিও কমপ্রেস (video_compressor_plus)
  // ============================================================

  /// ভিডিও ফাইল কমপ্রেস করে নতুন File ফেরত দেয়
  /// 
  /// - [quality]: VideoQuality.LowQuality / MediumQuality / HighQuality / VeryHighQuality
  /// - [deleteOriginal]: true হলে original ফাইল ডিলিট হবে
  /// 
  /// Error হলে original file ফেরত দেয় (safe)
  Future<File?> compressVideoFile(
    File file, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool deleteOriginal = false,
  }) async {
    try {
      // ১০ MB-র নিচে হলে কমপ্রেস skip
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

      final info = await VideoCompressor.compressVideo(
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

  /// Progress stream (0.0 .. 1.0)
  /// 
  /// video_compressor_plus থেকে progress 0..100 আসে
  /// এই মেথড সেটাকে 0.0..1.0-এ রূপান্তর করে
  Stream<double> videoProgressStream() {
    return VideoCompressor.compressProgress$.map(
      (progress) => (progress / 100).clamp(0.0, 1.0),
    );
  }

  /// কমপ্রেসের আগে ভিডিওর তথ্য
  Future<MediaInfo?> getVideoInfo(String path) async {
    try {
      return await VideoCompressor.getMediaInfo(path);
    } catch (_) {
      return null;
    }
  }

  /// কমপ্রেস বাতিল
  Future<void> cancelCompress() async {
    try {
      await VideoCompressor.cancelCompression();
    } catch (_) {}
  }

  /// Temp files clear
  Future<void> deleteAllCache() async {
    try {
      await VideoCompressor.deleteAllCache();
    } catch (_) {}
  }
}
