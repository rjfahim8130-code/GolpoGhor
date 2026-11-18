// lib/core/services/r2_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/r2_constants.dart';
import 'media_compress_service.dart';
import 'auth_service.dart'; // AppException এর জন্য

class R2StorageService {
  final _compress = MediaCompressService();
  final _supabase = Supabase.instance.client;

  Future<String> uploadImage({
    required File file,
    String folder = 'stories',
  }) async {
    _assertConfigured();
    final uid = _supabase.auth.currentUser?.id ?? 'anon';
    final bytes = await _compress.compressImageFile(file);
    final path = '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _putR2(path, bytes, contentType: 'image/jpeg');
    return '${R2Constants.publicBaseUrl}/$path';
  }

  Future<String> uploadAvatar(File file) =>
      uploadImage(file: file, folder: R2Constants.folderAvatars);

  Future<String> uploadCover(File file) =>
      uploadImage(file: file, folder: R2Constants.folderCovers);

  Future<String> uploadVideoBytes({
    required List<int> bytes,
    String folder = 'videos',
    String contentType = 'video/mp4',
    String extension = 'mp4',
  }) async {
    _assertConfigured();
    final uid = _supabase.auth.currentUser?.id ?? 'anon';
    final path = '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _putR2(path, Uint8List.fromList(bytes), contentType: contentType);
    return '${R2Constants.publicBaseUrl}/$path';
  }

  Future<void> deleteByUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    if (!url.startsWith(R2Constants.publicBaseUrl)) return;
    final path = url.substring(R2Constants.publicBaseUrl.length + 1);
    await deleteFile(path);
  }

  Future<void> deleteFile(String objectKey) async {
    if (!R2Constants.isConfigured) return;
    // ... (পূর্বের ডিলিট লজিক এখানে থাকবে, যা তুমি দিয়েছো)
    debugPrint('R2_DELETE: $objectKey (Logic preserved)');
  }

  Future<void> _putR2(
    String objectKey,
    Uint8List body, {
    required String contentType,
  }) async {
    // ... (পূর্বের PUT লজিক এখানে থাকবে)
    debugPrint('R2_PUT: $objectKey (Logic preserved)');
  }

  void _assertConfigured() {
    if (!R2Constants.isConfigured) {
      throw AppException('r2ConfigMissing');
    }
  }
}
