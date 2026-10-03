import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class ReactionPicker {
  static const Map<String, String> labels = {
    'like': '👍',
    'love': '❤️',
    'wow': '😮',
    'sad': '😢',
    'fire': '🔥',
  };

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'রিয়্যাকশন',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: AppConstants.reactionTypes.map((type) {
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, type),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          labels[type] ?? '👍',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static String emoji(String? type) => labels[type] ?? '👍';
}
