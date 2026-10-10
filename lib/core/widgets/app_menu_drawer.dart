// lib/core/widgets/app_menu_drawer.dart
// সংশোধিত: username বাদ, এডমিন conspicuous, localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/video_feature_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../routing/route_names.dart';
import 'cached_avatar.dart';

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
            // ---------------- হেডার ----------------
            InkWell(
              onTap: () {
                Navigator.pop(context);
                if (userId != null && userId!.isNotEmpty) {
                  context.push('${RouteNames.user}/$userId');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CachedAvatar(
                          userId: userId,
                          imageUrl: userAvatar,
                          name: userName ?? 'ইউজার',
                          radius: 26,
                          tappable: false,
                        ),
                        if (isAdmin)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName ?? 'ইউজার',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.danger.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.danger
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _tile(context, Icons.home_outlined, l10n.home,
                      RouteNames.home),
                  _tile(context, Icons.explore_outlined, l10n.discover,
                      RouteNames.discover),
                  _tile(context, Icons.star_outline, l10n.popular,
                      RouteNames.popular),
                  _tile(context, Icons.local_fire_department_outlined,
                      l10n.trending, RouteNames.trending),
                  _tile(context, Icons.search, l10n.search,
                      RouteNames.search),
                  if (videoOn)
                    _tile(context, Icons.videocam_outlined, l10n.videos,
                        RouteNames.videos),
                  _tile(context, Icons.notifications_outlined,
                      l10n.notifications, RouteNames.notifications),
                  const Divider(),
                  _tile(context, Icons.article_outlined, l10n.myWorks,
                      RouteNames.myWorks),
                  _tile(context, Icons.insights_outlined, l10n.insights,
                      RouteNames.insights),
                  _tile(context, Icons.bookmark_outline, l10n.saved,
                      RouteNames.saved),
                  _tile(context, Icons.drafts_outlined, l10n.drafts,
                      RouteNames.drafts),
                  _tile(context, Icons.download_outlined, l10n.download,
                      RouteNames.offline),
                  const Divider(),

                  // এডমিন সেকশন conspicuous
                  if (isAdmin) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 16,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ADMIN SECTIONS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _tile(
                      context,
                      Icons.admin_panel_settings_outlined,
                      l10n.adminDashboard,
                      RouteNames.admin,
                      color: AppColors.danger,
                    ),
                    const Divider(),
                  ],

                  _tile(context, Icons.settings_outlined, l10n.settings,
                      RouteNames.settings),
                  _tile(context, Icons.description_outlined, l10n.terms,
                      '${RouteNames.legal}/terms'),
                  _tile(context, Icons.privacy_tip_outlined, l10n.privacy,
                      '${RouteNames.legal}/privacy'),
                  const Divider(),

                  // Theme shortcut
                  ListTile(
                    leading: Icon(_themeIcon(themeMode)),
                    title: Text(
                      '${l10n.theme}: ${_themeLabel(themeMode, l10n)}',
                    ),
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
    String route, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: color != null ? TextStyle(color: color) : null,
      ),
      onTap: () {
        Navigator.pop(context);
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

  String _themeLabel(ThemeMode m, AppLocalizations l10n) {
    switch (m) {
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.system:
        return l10n.system;
    }
  }
}
