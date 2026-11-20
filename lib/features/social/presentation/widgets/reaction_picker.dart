// lib/features/social/presentation/widgets/reaction_picker.dart
// সংশোধিত: localization-ready (l10n.reaction + reaction name)

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class ReactionPicker {
  ReactionPicker._();

  static const Map<String, String> _labels = {
    'like': '👍',
    'love': '❤️',
    'wow': '😮',
    'sad': '😢',
    'fire': '🔥',
  };

  static String emoji(String? type) => _labels[type] ?? '👍';

  /// locale-aware reaction name (l10n থেকে)
  /// যেমন: reactionLike, reactionLove, reactionWow, reactionSad, reactionFire
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
      case 'like':
        return AppColors.like;
      case 'love':
        return AppColors.love;
      case 'wow':
        return AppColors.wow;
      case 'sad':
        return AppColors.sad;
      case 'fire':
        return AppColors.fire;
      default:
        return AppColors.primary;
    }
  }

  static Future<String?> show(BuildContext context) {
    final l10n = context.l10n;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.reaction,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                              style: const TextStyle(fontSize: 11),
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
