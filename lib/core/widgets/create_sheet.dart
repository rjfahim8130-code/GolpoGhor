// lib/core/widgets/create_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/video_feature_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../routing/route_names.dart';

class CreateSheet {
  CreateSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _CreateSheetBody(),
    );
  }
}

class _CreateSheetBody extends ConsumerWidget {
  const _CreateSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final videoOn = ref.watch(videoFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Container(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.create,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Story
              _actionTile(
                context: context,
                icon: Icons.article_outlined,
                title: l10n.newStory,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.writeStory);
                },
              ),
              const SizedBox(height: 12),
              
              // Novel
              _actionTile(
                context: context,
                icon: Icons.menu_book_outlined,
                title: l10n.newNovel,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RouteNames.writeNovel);
                },
              ),
              
              // Video (Only if enabled)
              if (videoOn) ...[
                const SizedBox(height: 12),
                _actionTile(
                  context: context,
                  icon: Icons.videocam_outlined,
                  title: l10n.newVideo,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(RouteNames.createVideo);
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
