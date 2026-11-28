// lib/core/widgets/create_sheet.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/route_names.dart';
import '../localization/app_localizations.dart';

class CreateSheet {
  CreateSheet._();

  static const Color _brandGreen = Color(0xFF159447);

  static Future<void> show(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetBg =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final handleColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.create,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                _actionTile(
                  icon: Icons.article_outlined,
                  label: l10n.newStory,
                  textColor: primaryText,
                  chevronColor: secondaryText,
                  borderColor: handleColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(RouteNames.writeStory);
                  },
                ),
                _actionTile(
                  icon: Icons.menu_book_outlined,
                  label: l10n.newNovel,
                  textColor: primaryText,
                  chevronColor: secondaryText,
                  borderColor: handleColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(RouteNames.writeNovel);
                  },
                ),
                _actionTile(
                  icon: Icons.videocam_outlined,
                  label: l10n.newVideo,
                  textColor: primaryText,
                  chevronColor: secondaryText,
                  borderColor: handleColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push(RouteNames.createVideo);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _actionTile({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color chevronColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: _brandGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _brandGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
