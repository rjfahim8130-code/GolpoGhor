// lib/core/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('bn-BD');
    } catch (_) {
      try {
        await _tts.setLanguage('bn-IN');
      } catch (_) {
        await _tts.setLanguage('en-US');
      }
    }
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    await _ensureInit();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> pause() async => _tts.pause();

  Future<void> stop() async => _tts.stop();

  Future<List<String>> getLanguages() async {
    final langs = await _tts.getLanguages;
    if (langs is List) {
      return langs.map((e) => e.toString()).toList();
    }
    return [];
  }
}
