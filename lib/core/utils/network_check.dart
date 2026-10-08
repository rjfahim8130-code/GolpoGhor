import 'dart:async';
import 'dart:io';

/// দ্রুত অনলাইন/অফলাইন চেক (কোনো অতিরিক্ত প্যাকেজ লাগে না)
class NetworkCheck {
  /// true = নেট আছে বলে ধরা যায়
  static Future<bool> isOnline({
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    try {
      final result = await InternetAddress.lookup('dns.google')
          .timeout(timeout);
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
