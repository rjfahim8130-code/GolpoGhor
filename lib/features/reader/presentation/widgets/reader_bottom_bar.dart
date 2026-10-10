import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// রিডারের নিচের বেগুনি বার — সব স্ক্রিনে একই
class ReaderBottomBar extends StatelessWidget {
  final List<ReaderBottomBarItem> items;

  const ReaderBottomBar({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items
                .map(
                  (item) => _Btn(
                    icon: item.icon,
                    label: item.label,
                    onTap: item.onTap,
                    loading: item.loading,
                    active: item.active,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class ReaderBottomBarItem {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool active;

  const ReaderBottomBarItem({
    this.icon,
    required this.label,
    this.onTap,
    this.loading = false,
    this.active = false,
  });
}

class _Btn extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool active;

  const _Btn({
    this.icon,
    required this.label,
    this.onTap,
    this.loading = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? Colors.white38
        : (active ? Colors.white : Colors.white);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(icon ?? Icons.circle, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
