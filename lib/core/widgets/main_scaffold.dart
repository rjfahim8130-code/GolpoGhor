// lib/core/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/route_names.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import 'create_sheet.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainScaffold({super.key, required this.child, required this.currentRoute});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _getIndex() {
    if (widget.currentRoute.startsWith(RouteNames.inbox)) return 1;
    if (widget.currentRoute.startsWith(RouteNames.videos)) return 3;
    if (widget.currentRoute.startsWith(RouteNames.profile) || widget.currentRoute.startsWith(RouteNames.user)) return 4;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        if (widget.currentRoute != RouteNames.home) context.go(RouteNames.home);
        break;
      case 1:
        if (widget.currentRoute != RouteNames.inbox) context.go(RouteNames.inbox);
        break;
      case 2:
        CreateSheet.show(context);
        break;
      case 3:
        if (widget.currentRoute != RouteNames.videos) context.go(RouteNames.videos);
        break;
      case 4:
        if (widget.currentRoute != RouteNames.profile) context.go(RouteNames.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final idx = _getIndex();

    return Scaffold(
      body: widget.child,
      // পুরো বটম বার সবুজ (#159447)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary, 
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
                  onTap: () => _onTap(0)
                ),
                _NavItem(
                  icon: Icons.forum_outlined, 
                  activeIcon: Icons.forum, 
                  label: l10n.inbox, 
                  selected: idx == 1, 
                  onTap: () => _onTap(1)
                ),
                _CreateButton(onTap: () => _onTap(2), label: l10n.create),
                _NavItem(
                  icon: Icons.video_library_outlined, 
                  activeIcon: Icons.video_library, 
                  label: l10n.videos, 
                  selected: idx == 3, 
                  onTap: () => _onTap(3)
                ),
                _NavItem(
                  icon: Icons.person_outline, 
                  activeIcon: Icons.person, 
                  label: l10n.profile, 
                  selected: idx == 4, 
                  onTap: () => _onTap(4)
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

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // সব আইকন সাদা, তবে সিলেক্টেড হলে একটু বেশি উজ্জ্বল (opacity) বা বোল্ড হবে
    final color = selected ? Colors.white : Colors.white70;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.white12,
        splashColor: Colors.white24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                fontSize: 10, 
                color: color, 
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500
              )
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
        highlightColor: Colors.white12,
        splashColor: Colors.white24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // মাঝখানের বাটন: সাদা সার্কেল, ভেতরে সবুজ প্লাস (অথবা আপনার ছবির মতো)
            Container(
              width: 42, 
              height: 42, 
              decoration: const BoxDecoration(
                color: Colors.white, // সাদা ব্যাকগ্রাউন্ড
                shape: BoxShape.circle, 
              ), 
              child: const Icon(Icons.add, color: AppColors.primary, size: 26) // সবুজ প্লাস
            ),
            const SizedBox(height: 2),
            Text(
              label, 
              style: const TextStyle(
                fontSize: 10, 
                color: Colors.white, // সাদা টেক্সট
                fontWeight: FontWeight.w500
              )
            ),
          ],
        ),
      ),
    );
  }
}
