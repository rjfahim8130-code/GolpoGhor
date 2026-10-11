// lib/core/utils/validators.dart
// username validator বাদ (username feature নেই)
// সব message এখন l10n key string — UI-তে translate হবে

import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class Validators {
  Validators._();

  static String? email(BuildContext context, String? v) {
    final l10n = context.l10n;
    if (v == null || v.trim().isEmpty) return l10n.valEnterEmail;
    final t = v.trim();
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(t)) {
      return l10n.valValidEmail;
    }
    return null;
  }

  static String? password(BuildContext context, String? v) {
    final l10n = context.l10n;
    if (v == null || v.isEmpty) return l10n.valEnterPassword;
    if (v.length < 6) return l10n.valMinSix;
    return null;
  }

  static String? name(BuildContext context, String? v) {
    final l10n = context.l10n;
    if (v == null || v.trim().isEmpty) return l10n.valEnterName;
    if (v.trim().length < 2) return l10n.valMinTwo;
    return null;
  }

  /// ডাক নাম — ঐচ্ছিক (খালি থাকলে valid)
  static String? nickname(BuildContext context, String? v) {
    final l10n = context.l10n;
    if (v == null || v.trim().isEmpty) return null;
    final t = v.trim();
    if (t.length < 2) return l10n.valMinTwo;
    if (t.length > 30) return l10n.valMaxThirty;
    return null;
  }

  static String? title(BuildContext context, String? v) {
    final l10n = context.l10n;
    if (v == null || v.trim().isEmpty) return l10n.valEnterTitle;
    if (v.trim().length < 2) return l10n.valMinTwo;
    return null;
  }

  static String? required(BuildContext context, String? v, String msg) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }
}
