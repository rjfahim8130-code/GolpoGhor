import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ডার্ক মোডে সাদা, লাইট মোডে কালো (যাতে ফেসবুকের মতো ঝকঝকে দেখায়)
    final defaultIconColor = isDark ? AppColors.darkText : AppColors.lightText;

    return PopupMenuButton<int>(
      icon: Icon(
        Icons.more_vert, // লম্বালম্বি ৩ ডট যেমন ছিল তেমনই আছে
        color: iconColor ?? defaultIconColor,
        size: iconSize,
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      onSelected: (i) => items[i].onTap(),
      itemBuilder: (_) => List.generate(items.length, (i) {
        final item = items[i];
        return PopupMenuItem<int>(
          value: i,
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: item.danger ? AppColors.danger : defaultIconColor,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: item.danger ? AppColors.danger : defaultIconColor,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
