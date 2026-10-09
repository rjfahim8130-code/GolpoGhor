import 'dart:async';
import 'dart:io';

/// দ্রুত অনলাইন/অফলাইন চেক
class NetworkCheck {
  NetworkCheck._();

  static Future<bool> isOnline({
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    try {
      final result = await InternetAddress.lookup('dns.google').timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
