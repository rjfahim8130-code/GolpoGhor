// lib/core/widgets/app_menu_drawer.dart
// শুধুমাত্র লেখক-কেন্দ্রিক এবং প্রয়োজনীয় অপশনগুলো রাখা হয়েছে

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../routing/route_names.dart';
import 'cached_avatar.dart';

class AppMenuDrawer extends ConsumerWidget {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? _bgDark : _bgLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
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
                decoration: BoxDecoration(
                  color: _brandGreen.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CachedAvatar(
                          userId: userId,
                          imageUrl: userAvatar,
                          name: userName ?? l10n.user,
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
                                color: _dangerColor,
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
                            userName ?? l10n.user,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
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
                                color: _dangerColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _dangerColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _dangerColor,
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
                  _tile(
                    context,
                    Icons.article_outlined,
                    l10n.myWorks,
                    RouteNames.myWorks,
                    primaryText,
                  ),
                  _tile(
                    context,
                    Icons.insights_outlined,
                    l10n.insights,
                    RouteNames.insights,
                    primaryText,
                  ),
                  _tile(
                    context,
                    Icons.bookmark_outline,
                    l10n.saved,
                    RouteNames.saved,
                    primaryText,
                  ),
                  _tile(
                    context,
                    Icons.drafts_outlined,
                    l10n.drafts,
                    RouteNames.drafts,
                    primaryText,
                  ),
                  _tile(
                    context,
                    Icons.download_outlined,
                    l10n.download,
                    RouteNames.offline,
                    primaryText,
                  ),
                  _tile(
                    context,
                    Icons.history,
                    l10n.recent,
                    RouteNames.history,
                    primaryText,
                  ),
                  Divider(color: borderColor),
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
                        color: _dangerColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _dangerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 16,
                            color: _dangerColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ADMIN SECTIONS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _dangerColor,
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
                      primaryText,
                      color: _dangerColor,
                    ),
                  ],
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
    Color textColor, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? _brandGreen),
      title: Text(label, style: TextStyle(color: color ?? textColor)),
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
    );
  }
}
