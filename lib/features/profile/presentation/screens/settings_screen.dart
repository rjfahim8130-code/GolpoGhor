import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('থিম', style: TextStyle(fontWeight: FontWeight.bold)),
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
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('পাসওয়ার্ড সেট / পরিবর্তন'),
            onTap: () => context.push('/set-password'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('শর্তাবলী'),
            onTap: () => context.push('/legal/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('প্রাইভেসি'),
            onTap: () => context.push('/legal/privacy'),
          ),
          const Divider(),
          const ListTile(
            title: Text('গল্পঘর'),
            subtitle: Text('ভার্সন 1.0.0'),
          ),
        ],
      ),
    );
  }
}
