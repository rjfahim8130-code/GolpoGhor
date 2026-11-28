// lib/features/profile/presentation/widgets/profile_quick_actions.dart
// সংশোধিত: localization যোগ

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class ProfileQuickActions extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF159447);

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
    final boxBg =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

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
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: actions.map((a) {
        return InkWell(
          onTap: a.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: boxBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                Icon(a.icon, color: _brandGreen, size: 26),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
                  maxLines: 2,
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

  _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
