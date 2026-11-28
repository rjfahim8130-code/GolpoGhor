// lib/core/utils/error_mapper.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_localizations.dart';
import '../services/auth_service.dart';

class ErrorMapper {
  ErrorMapper._();

  static String get(BuildContext context, Object e) {
    final l10n = context.l10n;

    // ১. কাস্টম AppException (যেমন: notLoggedIn, commentEmpty)
    if (e is AppException) {
      final translated = l10n.t(e.key);
      return translated != e.key ? translated : l10n.somethingWentWrong;
    }

    // ২. Supabase Auth Exception (লগইন, রেজিস্টার)
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return l10n.t('invalidCredentials');
      }
      if (msg.contains('email not confirmed')) {
        return l10n.t('emailNotConfirmed');
      }
      if (msg.contains('user already registered')) {
        return l10n.t('userAlreadyRegistered');
      }
      if (msg.contains('password should be at least')) {
        return l10n.passwordMinSix;
      }
      if (msg.contains('invalid email')) {
        return l10n.enterValidEmail;
      }
      return l10n.loginFailed;
    }

    // ৩. Supabase Database Exception
    if (e is PostgrestException) {
      if (e.message.contains('duplicate key') || e.code == '23505') {
        return l10n.t('alreadyExists');
      }
      return l10n.somethingWentWrong;
    }

    // ৪. নেটওয়ার্ক বা অন্যান্য
    return l10n.somethingWentWrong;
  }
}
