import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // ---------- Theme ----------
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'থিম',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('সিস্টেম'),
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
            title: const Text('লাইট'),
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
            title: const Text('ডার্ক'),
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

          // ---------- Language ----------
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'ভাষা',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<String>(
            title: const Text('বাংলা'),
            value: 'bn',
            groupValue: currentLocale.languageCode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) {
                ref.read(localeProvider.notifier).setLocale(v);
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: currentLocale.languageCode,
            activeColor: AppColors.primary,
            onChanged: (v) {
              if (v != null) {
                ref.read(localeProvider.notifier).setLocale(v);
              }
            },
          ),

          const Divider(),

          // ---------- Account ----------
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('পাসওয়ার্ড সেট / পরিবর্তন'),
            onTap: () => context.push(RouteNames.setPassword),
          ),

          const Divider(),

          // ---------- Legal ----------
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('শর্তাবলী'),
            onTap: () => context.push('${RouteNames.legal}/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('প্রাইভেসি'),
            onTap: () => context.push('${RouteNames.legal}/privacy'),
          ),

          const Divider(),

          // ---------- About ----------
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppConstants.appName),
            subtitle: Text('ভার্সন ${AppConstants.appVersion}'),
          ),
        ],
      ),
    );
  }
}
