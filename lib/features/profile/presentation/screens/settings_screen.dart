// lib/features/profile/presentation/screens/settings_screen.dart
// সম্পূর্ণ নতুন: logout, delete account, language default system, localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final localeCode = ref.read(localeProvider.notifier).currentCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // ---------------- Theme ----------------
          _sectionTitle(context, l10n.theme),
          RadioListTile<ThemeMode>(
            title: Text(l10n.system),
            value: ThemeMode.system,
            groupValue: currentMode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) {
                ref.read(themeModeProvider.notifier).setMode(v);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.light),
            value: ThemeMode.light,
            groupValue: currentMode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) {
                ref.read(themeModeProvider.notifier).setMode(v);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.dark),
            value: ThemeMode.dark,
            groupValue: currentMode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) {
                ref.read(themeModeProvider.notifier).setMode(v);
              }
            },
          ),
          const Divider(),

          // ---------------- Language ----------------
          _sectionTitle(context, l10n.language),
          RadioListTile<String>(
            title: Text(l10n.system),
            subtitle: Text(
              'Phone language-এর অনুযায়ী',
              style: const TextStyle(fontSize: 12),
            ),
            value: 'system',
            groupValue: localeCode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              ref.read(localeProvider.notifier).setLocale('system');
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.bangla),
            value: 'bn',
            groupValue: localeCode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              ref.read(localeProvider.notifier).setLocale('bn');
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.english),
            value: 'en',
            groupValue: localeCode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              ref.read(localeProvider.notifier).setLocale('en');
            },
          ),
          const Divider(),

          // ---------------- Account ----------------
          _sectionTitle(context, l10n.profile),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text('পাসওয়ার্ড সেট / পরিবর্তন'),
            onTap: () => context.push(RouteNames.setPassword),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.warning),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: AppColors.warning),
            ),
            onTap: () => _confirmLogout(context, ref, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.danger),
            title: Text(
              l10n.deleteAccount,
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: () => _confirmDeleteAccount(context, ref, l10n),
          ),
          const Divider(),

          // ---------------- Legal ----------------
          _sectionTitle(context, l10n.legal),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.terms),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('${RouteNames.legal}/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('${RouteNames.legal}/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(l10n.supportEmail),
            subtitle: const Text('support@golpoghor.app'),
          ),
          const Divider(),

          // ---------------- About ----------------
          _sectionTitle(context, l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appName),
            subtitle: Text('${l10n.version} ${AppConstants.appVersion}'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService().signOut();
    if (context.mounted) context.go(RouteNames.welcome);
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ডিলিট করুন',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // পরবর্তী ব্যাচে deletion service যোগ হবে
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeletionScheduled)),
      );
    }
  }
}
