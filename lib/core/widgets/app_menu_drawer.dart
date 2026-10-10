import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/video_feature_provider.dart';
import '../theme/app_colors.dart';
import 'cached_avatar.dart';

/// সাইড ড্রয়ার — থ্রি-লাইন মেনু
/// প্রোফাইল থেকে খোলা হবে
class AppMenuDrawer extends ConsumerWidget {
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final bool isAdmin;

  const AppMenuDrawer({
    super.key,
    this.userId,
    this.userName,
    this.userAvatar,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final videoOn = ref.watch(videoFeatureProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // হেডার
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  CachedAvatar(
                    userId: userId,
                    imageUrl: userAvatar,
                    name: userName ?? 'ইউজার',
                    radius: 26,
                    tappable: false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName ?? 'ইউজার',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _tile(context, Icons.home_outlined, l10n.home, '/home'),
                  _tile(context, Icons.explore_outlined, l10n.discover,
                      '/discover'),
                  _tile(context, Icons.star_outline, l10n.popular, '/popular'),
                  _tile(context, Icons.local_fire_department_outlined,
                      l10n.trending, '/trending'),
                  _tile(context, Icons.search, l10n.search, '/search'),
                  if (videoOn)
                    _tile(context, Icons.videocam_outlined, l10n.videos,
                        '/videos'),
                  _tile(context, Icons.notifications_outlined,
                      l10n.notifications, '/notifications'),
                  const Divider(),
                  _tile(context, Icons.article_outlined, l10n.myWorks,
                      '/my-works'),
                  _tile(context, Icons.insights_outlined, l10n.insights,
                      '/insights'),
                  _tile(context, Icons.bookmark_outline, l10n.saved, '/saved'),
                  _tile(context, Icons.drafts_outlined, l10n.drafts, '/drafts'),
                  _tile(context, Icons.download_outlined, l10n.download,
                      '/offline'),
                  const Divider(),
                  _tile(context, Icons.settings_outlined, l10n.settings,
                      '/settings'),
                  _tile(context, Icons.description_outlined, l10n.terms,
                      '/legal/terms'),
                  _tile(context, Icons.privacy_tip_outlined, l10n.privacy,
                      '/legal/privacy'),
                  if (isAdmin)
                    _tile(context, Icons.admin_panel_settings_outlined,
                        l10n.admin, '/admin'),
                  const Divider(),
                  // থিম shortcut
                  ListTile(
                    leading: Icon(_themeIcon(themeMode)),
                    title: Text('${l10n.theme}: ${_themeLabel(themeMode)}'),
                    onTap: () {
                      final next = themeMode == ThemeMode.light
                          ? ThemeMode.dark
                          : themeMode == ThemeMode.dark
                              ? ThemeMode.system
                              : ThemeMode.light;
                      ref.read(themeModeProvider.notifier).setMode(next);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // close drawer
        context.push(route);
      },
    );
  }

  IconData _themeIcon(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'লাইট';
      case ThemeMode.dark:
        return 'ডার্ক';
      case ThemeMode.system:
        return 'সিস্টেম';
    }
  }
}
