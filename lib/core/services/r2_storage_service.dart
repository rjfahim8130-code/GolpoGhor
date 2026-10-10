import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/r2_constants.dart';
import 'media_compress_service.dart';

/// শুধু Cloudflare R2 — Supabase Storage নেই
class R2StorageService {
  final _compress = MediaCompressService();
  final _supabase = Supabase.instance.client;

  // ---------- Upload ----------

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
    final path =
        '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _putR2(path, Uint8List.fromList(bytes), contentType: contentType);
    return '${R2Constants.publicBaseUrl}/$path';
  }

  // ---------- Delete ----------

  /// URL থেকে path বের করে R2 থেকে ডিলিট
  Future<void> deleteByUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    if (!url.startsWith(R2Constants.publicBaseUrl)) return;

    final path = url.substring(R2Constants.publicBaseUrl.length + 1);
    await deleteFile(path);
  }

  /// সরাসরি path দিয়ে ডিলিট (folder/uid/file.jpg)
  Future<void> deleteFile(String objectKey) async {
    if (!R2Constants.isConfigured) return;
    final host = '${R2Constants.accountId}.r2.cloudflarestorage.com';
    final bucket = R2Constants.bucketName;
    final canonicalUri = '/$bucket/$objectKey';

    const method = 'DELETE';
    const service = 's3';
    const region = 'auto';

    final now = DateTime.now().toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final amzDate =
        '${now.year}${two(now.month)}${two(now.day)}T'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}Z';
    final dateStamp = '${now.year}${two(now.month)}${two(now.day)}';

    final payloadHash = sha256.convert(const <int>[]).toString();
    final canonicalHeaders =
        'host:$host\n'
        'x-amz-content-sha256:$payloadHash\n'
        'x-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest = [
      method,
      canonicalUri,
      '',
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    List<int> hmacSha256(List<int> key, String data) {
      return Hmac(sha256, key).convert(utf8.encode(data)).bytes;
    }

    final kDate = hmacSha256(utf8.encode('AWS4${R2Constants.secretAccessKey}'), dateStamp);
    final kRegion = hmacSha256(kDate, region);
    final kService = hmacSha256(kRegion, service);
    final kSigning = hmacSha256(kService, 'aws4_request');
    final signature =
        Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

    final authorization =
        'AWS4-HMAC-SHA256 Credential=${R2Constants.accessKeyId}/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    final uri = Uri.parse('https://$host$canonicalUri');
    try {
      await http.delete(
        uri,
        headers: {
          'Host': host,
          'x-amz-content-sha256': payloadHash,
          'x-amz-date': amzDate,
          'Authorization': authorization,
        },
      );
    } catch (_) {
      // ডিলিট ব্যর্থ হলেও অ্যাপ চলবে
    }
  }

  // ---------- Core PUT ----------

  Future<void> _putR2(
    String objectKey,
    Uint8List body, {
    required String contentType,
  }) async {
    final accessKey = R2Constants.accessKeyId;
    final secretKey = R2Constants.secretAccessKey;
    final bucket = R2Constants.bucketName;
    final host = '${R2Constants.accountId}.r2.cloudflarestorage.com';
    const method = 'PUT';
    const service = 's3';
    const region = 'auto';

    final now = DateTime.now().toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final amzDate =
        '${now.year}${two(now.month)}${two(now.day)}T'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}Z';
    final dateStamp = '${now.year}${two(now.month)}${two(now.day)}';

    final payloadHash = sha256.convert(body).toString();
    final canonicalUri = '/$bucket/$objectKey';
    final canonicalHeaders =
        'content-type:$contentType\n'
        'host:$host\n'
        'x-amz-content-sha256:$payloadHash\n'
        'x-amz-date:$amzDate\n';
    const signedHeaders = 'content-type;host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest = [
      method,
      canonicalUri,
      '',
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    List<int> hmacSha256(List<int> key, String data) {
      return Hmac(sha256, key).convert(utf8.encode(data)).bytes;
    }

    final kDate = hmacSha256(utf8.encode('AWS4$secretKey'), dateStamp);
    final kRegion = hmacSha256(kDate, region);
    final kService = hmacSha256(kRegion, service);
    final kSigning = hmacSha256(kService, 'aws4_request');
    final signature =
        Hmac(sha256, kSigning).convert(utf8.encode(stringToSign)).toString();

    final authorization =
        'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    final uri = Uri.parse('https://$host$canonicalUri');
    final res = await http.put(
      uri,
      headers: {
        'Content-Type': contentType,
        'Host': host,
        'x-amz-content-sha256': payloadHash,
        'x-amz-date': amzDate,
        'Authorization': authorization,
      },
      body: body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('R2 আপলোড ব্যর্থ: ${res.statusCode} ${res.body}');
    }
  }

  void _assertConfigured() {
    if (!R2Constants.isConfigured) {
      throw Exception(
        'Cloudflare R2 কনফিগ নেই। R2_ACCESS_KEY ও R2_SECRET_KEY (dart-define) দিন।',
      );
    }
  }
}
