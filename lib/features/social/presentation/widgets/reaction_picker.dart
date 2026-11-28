// lib/features/social/presentation/widgets/reaction_picker.dart
// সংশোধিত: localization-ready (l10n.reaction + reaction name)

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';

class ReactionPicker {
  ReactionPicker._();

  static const Color _brandGreen = Color(0xFF159447);

  static const Map<String, String> _labels = {
    'like': '👍',
    'love': '❤️',
    'wow': '😮',
    'sad': '😢',
    'fire': '🔥',
  };

  static String emoji(String? type) => _labels[type] ?? '👍';

  static String name(BuildContext context, String? type) {
    final l10n = context.l10n;
    switch (type) {
      case 'like':
        return l10n.reactionLike;
      case 'love':
        return l10n.reactionLove;
      case 'wow':
        return l10n.reactionWow;
      case 'sad':
        return l10n.reactionSad;
      case 'fire':
        return l10n.reactionFire;
      default:
        return l10n.reactionLike;
    }
  }

  static Color color(String? type) {
    switch (type) {
      case 'love':
        return const Color(0xFFE41E3F);
      case 'like':
      case 'wow':
      case 'sad':
      case 'fire':
      default:
        return _brandGreen;
    }
  }

  static Future<String?> show(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final handleColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                  l10n.reaction,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: AppConstants.reactionTypes.map((type) {
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, type),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _labels[type] ?? '👍',
                              style: const TextStyle(fontSize: 34),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name(context, type),
                              style:
                                  TextStyle(fontSize: 11, color: primaryText),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
