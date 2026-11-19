// lib/core/widgets/create_sheet.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/route_names.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';

class CreateSheet {
  CreateSheet._();

  static Future<void> show(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(l10n.create, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _actionTile(icon: Icons.article_outlined, label: l10n.newStory, onTap: () { Navigator.pop(ctx); context.push(RouteNames.writeStory); }),
                _actionTile(icon: Icons.menu_book_outlined, label: l10n.newNovel, onTap: () { Navigator.pop(ctx); context.push(RouteNames.writeNovel); }),
                _actionTile(icon: Icons.videocam_outlined, label: l10n.newVideo, onTap: () { Navigator.pop(ctx); context.push(RouteNames.createVideo); }),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _actionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
