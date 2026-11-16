// lib/features/reader/presentation/widgets/reader_bottom_bar.dart
// শুধু আইকন সম্বলিত বটম বার (লেবেল ছাড়া)

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
      elevation: 8,
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
                    onTap: item.onTap,
                    loading: item.loading,
                    active: item.active,
                    tooltip: item.tooltip,
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
  final String tooltip;
  final VoidCallback? onTap;
  final bool loading;
  final bool active;

  const ReaderBottomBarItem({
    this.icon,
    required this.tooltip,
    this.onTap,
    this.loading = false,
    this.active = false,
  });
}

class _Btn extends StatelessWidget {
  final IconData? icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool loading;
  final bool active;

  const _Btn({
    this.icon,
    required this.tooltip,
    this.onTap,
    this.loading = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? Colors.white38 : (active ? Colors.amber : Colors.white);

    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon ?? Icons.circle, size: 24, color: color),
    );
  }
}
