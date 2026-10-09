class Validators {
  Validators._();

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'ইমেইল লিখুন';
    final t = v.trim();
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(t)) {
      return 'সঠিক ইমেইল লিখুন';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'পাসওয়ার্ড লিখুন';
    if (v.length < 6) return 'কমপক্ষে ৬ অক্ষর';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'নাম লিখুন';
    if (v.trim().length < 2) return 'কমপক্ষে ২ অক্ষর';
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.trim().length < 3) return 'কমপক্ষে ৩ অক্ষর';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v.trim().toLowerCase())) {
      return 'শুধু a-z, 0-9, _';
    }
    return null;
  }

  static String? title(String? v) {
    if (v == null || v.trim().isEmpty) return 'শিরোনাম লিখুন';
    if (v.trim().length < 2) return 'কমপক্ষে ২ অক্ষর';
    return null;
  }

  static String? required(String? v, String msg) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }
}
