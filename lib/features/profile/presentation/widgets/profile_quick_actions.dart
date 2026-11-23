// lib/features/profile/presentation/widgets/profile_quick_actions.dart
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileQuickActions extends StatelessWidget {
  final bool videoOn;
  final VoidCallback onNewStory;
  final VoidCallback onNewNovel;
  final VoidCallback? onNewVideo;
  final VoidCallback onEditProfile;

  const ProfileQuickActions({
    super.key,
    required this.videoOn,
    required this.onNewStory,
    required this.onNewNovel,
    required this.onEditProfile,
    this.onNewVideo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.article_outlined,
        label: l10n.newStory,
        onTap: onNewStory,
      ),
      _QuickAction(
        icon: Icons.menu_book_outlined,
        label: l10n.newNovel,
        onTap: onNewNovel,
      ),
      if (videoOn && onNewVideo != null)
        _QuickAction(
          icon: Icons.videocam_outlined,
          label: l10n.newVideo,
          onTap: onNewVideo!,
        ),
      _QuickAction(
        icon: Icons.edit_outlined,
        label: l10n.editProfile,
        onTap: onEditProfile,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: actions.map((a) {
        return InkWell(
          onTap: a.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 85,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Icon(a.icon, color: AppColors.primary, size: 24),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _QuickAction({required this.icon, required this.label, required this.onTap});
}
