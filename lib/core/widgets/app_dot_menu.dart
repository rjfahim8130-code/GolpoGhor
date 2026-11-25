// lib/core/widgets/app_dot_menu.dart
import 'package:flutter/material.dart';

/// থ্রি-ডট মেনু — যেখানে লাগবে একই রকম
class AppDotMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const AppDotMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
}

class AppDotMenu extends StatelessWidget {
  final List<AppDotMenuItem> items;
  final Color? iconColor;
  final double iconSize;

  const AppDotMenu({
    super.key,
    required this.items,
    this.iconColor,
    this.iconSize = 22,
  });

  static const Color _dangerColor = Color(0xFFE41E3F);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final menuBg =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final textColor =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return PopupMenuButton<int>(
      icon: Icon(
        Icons.more_vert,
        color: iconColor ?? defaultIconColor,
        size: iconSize,
      ),
      color: menuBg,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      onSelected: (i) => items[i].onTap(),
      itemBuilder: (_) => List.generate(items.length, (i) {
        final item = items[i];
        final itemColor = item.danger ? _dangerColor : textColor;
        return PopupMenuItem<int>(
          value: i,
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: itemColor,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(color: itemColor),
              ),
            ],
          ),
        );
      }),
    );
  }
}
