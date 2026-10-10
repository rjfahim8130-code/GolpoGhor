import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class MediaCompressService {
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

  /// Avatar-এর জন্য একটু ছোট (৮০০ px)
  Future<Uint8List> compressAvatar(File file) =>
      compressImageFile(file, maxWidth: 800, quality: 78);
}
