// lib/core/widgets/main_scaffold.dart
// Bottom Navigation Bar সহ main shell

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/discover_screen.dart';
import '../../features/home/presentation/screens/home_feed_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/video/presentation/screens/video_feed_screen.dart';
import '../../routing/route_names.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import 'create_sheet.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _getIndex() {
    if (widget.currentRoute.startsWith(RouteNames.discover)) return 1;
    if (widget.currentRoute.startsWith(RouteNames.videos)) return 3;
    if (widget.currentRoute.startsWith(RouteNames.profile) ||
        widget.currentRoute.startsWith(RouteNames.user)) {
      return 4;
    }
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        if (widget.currentRoute != RouteNames.home) {
          context.go(RouteNames.home);
        }
        break;
      case 1:
        if (widget.currentRoute != RouteNames.discover) {
          context.go(RouteNames.discover);
        }
        break;
      case 2:
        CreateSheet.show(context);
        break;
      case 3:
        if (widget.currentRoute != RouteNames.videos) {
          context.go(RouteNames.videos);
        }
        break;
      case 4:
        if (widget.currentRoute != RouteNames.profile) {
          context.go(RouteNames.profile);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idx = _getIndex();

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: l10n.home,
                  selected: idx == 0,
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: l10n.discover,
                  selected: idx == 1,
                  onTap: () => _onTap(1),
                ),
                _CreateButton(onTap: () => _onTap(2), label: l10n.create),
                _NavItem(
                  icon: Icons.videocam_outlined,
                  activeIcon: Icons.videocam,
                  label: l10n.videos,
                  selected: idx == 3,
                  onTap: () => _onTap(3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: l10n.profile,
                  selected: idx == 4,
                  onTap: () => _onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? AppColors.primary
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _CreateButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
