// lib/core/services/r2_storage_service.dart
// Upload via Supabase Edge Function (presigned URL). No R2 secret in the app.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/r2_constants.dart';
import 'auth_service.dart';
import 'media_compress_service.dart';

class R2StorageService {
  final _compress = MediaCompressService();
  final _supabase = Supabase.instance.client;

  static const String _fnCreateUploadUrl = 'create-upload-url';
  static const String _fnDeleteObject = 'delete-object';

  Future<String> uploadImage({
    required File file,
    String folder = 'stories',
  }) async {
    final bytes = await _compress.compressImageFile(file);
    return _uploadBytes(
      bytes: bytes,
      folder: folder,
      contentType: 'image/jpeg',
      extension: 'jpg',
    );
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
  }) {
    return _uploadBytes(
      bytes: Uint8List.fromList(bytes),
      folder: folder,
      contentType: contentType,
      extension: extension,
    );
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String contentType,
    required String extension,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw AppException('notLoggedIn');

    final path =
        '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final res = await _supabase.functions.invoke(
      _fnCreateUploadUrl,
      body: {
        'path': path,
        'contentType': contentType,
      },
    );

    if (res.status != 200) {
      debugPrint('CREATE_UPLOAD_URL_FAILED: ${res.status} ${res.data}');
      throw AppException('r2UploadFailed');
    }

    final data = res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};
    final uploadUrl = data['uploadUrl'] as String?;
    final publicUrl = data['publicUrl'] as String?;

    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw AppException('r2UploadFailed');
    }

    final put = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
      },
      body: bytes,
    );

    if (put.statusCode < 200 || put.statusCode >= 300) {
      debugPrint('R2_PRESIGNED_PUT_FAILED: ${put.statusCode} ${put.body}');
      throw AppException('r2UploadFailed');
    }

    if (publicUrl != null && publicUrl.isNotEmpty) return publicUrl;
    if (R2Constants.publicBaseUrl.isNotEmpty) {
      return '${R2Constants.publicBaseUrl}/$path';
    }
    return path;
  }

  Future<void> deleteByUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final base = R2Constants.publicBaseUrl;
    if (base.isEmpty || !url.startsWith(base)) return;
    final path = url.substring(base.length + (url.length > base.length && url[base.length] == '/' ? 1 : 0));
    final key = path.startsWith('/') ? path.substring(1) : path;
    await deleteFile(key);
  }

  Future<void> deleteFile(String objectKey) async {
    if (objectKey.isEmpty) return;
    try {
      final res = await _supabase.functions.invoke(
        _fnDeleteObject,
        body: {'path': objectKey},
      );
      if (res.status != 200) {
        debugPrint('R2_DELETE_FN_FAILED: ${res.status} ${res.data}');
      }
    } catch (e) {
      debugPrint('R2_DELETE_ERROR: $e');
    }
  }
}
