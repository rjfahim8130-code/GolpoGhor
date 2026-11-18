// lib/core/services/media_compress_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:rxdart/rxdart.dart';
import 'package:video_compress/video_compress.dart';
import '../constants/app_constants.dart';

class MediaCompressService {
  // AppConstants থেকে সাইজ নেওয়া হলো
  static const int _maxImageWidth = 1280;
  static const int _defaultQuality = 75;

  Future<Uint8List> compressImageFile(File file, {int? maxWidth, int? quality}) async {
    final bytes = await file.readAsBytes();
    return compressBytes(bytes, maxWidth: maxWidth ?? _maxImageWidth, quality: quality ?? _defaultQuality);
  }

  Future<Uint8List> compressBytes(Uint8List bytes, {required int maxWidth, required int quality}) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      img.Image out = decoded;
      if (out.width > maxWidth) {
        out = img.copyResize(out, width: maxWidth, interpolation: img.Interpolation.linear);
      }
      return Uint8List.fromList(img.encodeJpg(out, quality: quality));
    } catch (e) {
      debugPrint('IMAGE_COMPRESS_ERROR: $e');
      return bytes;
    }
  }

  Future<Uint8List> compressAvatar(File file) => compressImageFile(file, maxWidth: 800, quality: 78);

  Future<File?> compressVideoFile(File file, {VideoQuality quality = VideoQuality.MediumQuality, bool deleteOriginal = false}) async {
    try {
      final sizeInMB = await file.length() / (1024 * 1024);
      // AppConstants.maxUploadVideoMb এর বেশি হলে কমপ্রেস করবে
      if (sizeInMB < AppConstants.maxUploadVideoMb) return file;

      final info = await VideoCompress.compressVideo(file.path, quality: quality, deleteOrigin: deleteOriginal, includeAudio: true);
      if (info == null || info.file == null) return file;
      return info.file;
    } catch (e) {
      debugPrint('VIDEO_COMPRESS_ERROR: $e');
      return file; // fail হলেও original ফেরত দেবে
    }
  }
  
  // ... (subscribeProgress, getVideoInfo, cancelCompress, deleteAllCache ইত্যাদি আগের মতোই থাকবে)
}
