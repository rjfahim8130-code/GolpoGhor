import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// অ্যাডমিন ফিচার কন্ট্রোল সেকশন
/// বর্তমানে শুধু ভিডিও; ভবিষ্যতে আরো
class AdminFeatureToggles extends ConsumerWidget {
  const AdminFeatureToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoOn = ref.watch(videoFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        activeColor: AppColors.primary,
        title: const Text('ভিডিও ফিচার'),
        subtitle: Text(
          videoOn
              ? 'চালু — সবাই ভিডিও দেখতে ও আপলোড করতে পারবে'
              : 'বন্ধ — ভিডিও সংক্রান্ত সব লুকানো থাকবে',
          style: const TextStyle(fontSize: 12),
        ),
        secondary: Icon(
          videoOn ? Icons.videocam : Icons.videocam_off,
          color: videoOn ? AppColors.primary : Colors.grey,
        ),
        value: videoOn,
        onChanged: (v) async {
          try {
            await ref.read(videoFeatureProvider.notifier).setEnabled(v);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  v ? 'ভিডিও ফিচার চালু' : 'ভিডিও ফিচার বন্ধ',
                ),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        },
      ),
    );
  }
}
