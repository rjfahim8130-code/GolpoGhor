// lib/features/profile/presentation/screens/settings_screen.dart
// Theme, Language, Notification Controls, Account, Legal, About

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushEnabled = true;
  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _mentionsEnabled = true;
  bool _followersEnabled = true;
  bool _authorUpdatesEnabled = true;
  bool _savedContentUpdatesEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notif_push') ?? true;
      _likesEnabled = prefs.getBool('notif_likes') ?? true;
      _commentsEnabled = prefs.getBool('notif_comments') ?? true;
      _mentionsEnabled = prefs.getBool('notif_mentions') ?? true;
      _followersEnabled = prefs.getBool('notif_followers') ?? true;
      _authorUpdatesEnabled = prefs.getBool('notif_author_updates') ?? true;
      _savedContentUpdatesEnabled = prefs.getBool('notif_saved_updates') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    // ডেমো: টেস্ট করার জন্য নোটিফিকেশন দেখাবে
    if (value && key == 'notif_push') {
      PushNotificationService.instance.showNotification(
        id: 1,
        title: 'GolpoGhor',
        body: 'Notifications turned on!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentMode = ref.watch(themeModeProvider);
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
              if (v != null) ref.read(themeModeProvider.notifier).setMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.light),
            value: ThemeMode.light,
            groupValue: currentMode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) ref.read(themeModeProvider.notifier).setMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.dark),
            value: ThemeMode.dark,
            groupValue: currentMode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) ref.read(themeModeProvider.notifier).setMode(v);
            },
          ),
          const Divider(),

          // ---------------- Language ----------------
          _sectionTitle(context, l10n.language),
          RadioListTile<String>(
            title: Text(l10n.system),
            subtitle: Text(l10n.systemLanguageHint, style: const TextStyle(fontSize: 12)),
            value: 'system',
            groupValue: localeCode,
            activeColor: AppColors.primary,
            onChanged: (v) => ref.read(localeProvider.notifier).setLocale('system'),
          ),
          RadioListTile<String>(
            title: Text(l10n.bangla),
            value: 'bn',
            groupValue: localeCode,
            activeColor: AppColors.primary,
            onChanged: (v) => ref.read(localeProvider.notifier).setLocale('bn'),
          ),
          RadioListTile<String>(
            title: Text(l10n.english),
            value: 'en',
            groupValue: localeCode,
            activeColor: AppColors.primary,
            onChanged: (v) => ref.read(localeProvider.notifier).setLocale('en'),
          ),
          const Divider(),

          // ---------------- Notifications ----------------
          _sectionTitle(context, 'Notification Controls'),
          SwitchListTile(
            title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Main switch for all app notifications'),
            value: _pushEnabled,
            activeColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _pushEnabled = v);
              _saveSetting('notif_push', v);
            },
          ),
          if (_pushEnabled) ...[
            SwitchListTile(
              title: Text(l10n.like),
              value: _likesEnabled,
              onChanged: (v) {
                setState(() => _likesEnabled = v);
                _saveSetting('notif_likes', v);
              },
            ),
            SwitchListTile(
              title: Text(l10n.comment),
              value: _commentsEnabled,
              onChanged: (v) {
                setState(() => _commentsEnabled = v);
                _saveSetting('notif_comments', v);
              },
            ),
            SwitchListTile(
              title: Text(l10n.notifMentioned),
              value: _mentionsEnabled,
              onChanged: (v) {
                setState(() => _mentionsEnabled = v);
                _saveSetting('notif_mentions', v);
              },
            ),
            SwitchListTile(
              title: Text(l10n.follow),
              value: _followersEnabled,
              onChanged: (v) {
                setState(() => _followersEnabled = v);
                _saveSetting('notif_followers', v);
              },
            ),
            SwitchListTile(
              title: const Text('Author Updates'),
              subtitle: const Text('New stories from followed authors'),
              value: _authorUpdatesEnabled,
              onChanged: (v) {
                setState(() => _authorUpdatesEnabled = v);
                _saveSetting('notif_author_updates', v);
              },
            ),
            SwitchListTile(
              title: const Text('Saved Content Updates'),
              subtitle: const Text('New episodes of bookmarked stories'),
              value: _savedContentUpdatesEnabled,
              onChanged: (v) {
                setState(() => _savedContentUpdatesEnabled = v);
                _saveSetting('notif_saved_updates', v);
              },
            ),
          ],
          const Divider(),

          // ---------------- Account ----------------
          _sectionTitle(context, l10n.profile),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.setPassword),
            onTap: () => context.push(RouteNames.setPassword),
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: Text(l10n.settings),
            subtitle: const Text('Blocked users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.blockedUsers),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.warning),
            title: Text(l10n.logout, style: const TextStyle(color: AppColors.warning)),
            onTap: () => _confirmLogout(context, ref, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.danger),
            title: Text(l10n.deleteAccount, style: const TextStyle(color: AppColors.danger)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.deleteAccount),
          ),
          const Divider(),

          // ---------------- Legal & About ----------------
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
          const Divider(),

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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.logout)),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService().signOut();
    if (context.mounted) context.go(RouteNames.welcome);
  }
}
