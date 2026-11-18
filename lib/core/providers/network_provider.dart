// lib/core/providers/network_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/network_check.dart';

/// অনলাইন/অফলাইন অবস্থা
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, bool>((ref) {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends StateNotifier<bool> {
  NetworkStatusNotifier() : super(true) {
    _init();
  }

  Timer? _timer;

  Future<void> _init() async {
    await check();
    // প্রতি ১০ সেকেন্ডে চেক
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => check());
  }

  Future<bool> check() async {
    final online = await NetworkCheck.isOnline();
    if (mounted && state != online) state = online;
    return online;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// সহজ shortcut
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(networkStatusProvider);
});
