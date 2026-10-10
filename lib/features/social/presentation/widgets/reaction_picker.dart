import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// রিঅ্যাকশন পিকার — নিচ থেকে শিটে ইমোজি
class ReactionPicker {
  ReactionPicker._();

  static const Map<String, String> _labels = {
    'like': '👍',
    'love': '❤️',
    'wow': '😮',
    'sad': '😢',
    'fire': '🔥',
  };

  static const Map<String, String> _names = {
    'like': 'লাইক',
    'love': 'ভালোবাসা',
    'wow': 'অবাক',
    'sad': 'দুঃখ',
    'fire': 'দুর্দান্ত',
  };

  static String emoji(String? type) => _labels[type] ?? '👍';

  static String name(String? type) => _names[type] ?? 'লাইক';

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
                const Text(
                  'প্রতিক্রিয়া',
                  style: TextStyle(
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
                              _names[type] ?? '',
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
