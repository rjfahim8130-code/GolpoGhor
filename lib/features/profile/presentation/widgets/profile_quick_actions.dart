import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// প্রোফাইলে প্রাইমারি ৪টি অ্যাকশন
/// ভিডিও টগল অফ থাকলে ভিডিও বাটন দেখাবে না
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.article_outlined,
        label: 'নতুন গল্প',
        onTap: onNewStory,
      ),
      _QuickAction(
        icon: Icons.menu_book_outlined,
        label: 'নতুন উপন্যাস',
        onTap: onNewNovel,
      ),
      if (videoOn && onNewVideo != null)
        _QuickAction(
          icon: Icons.videocam_outlined,
          label: 'নতুন ভিডিও',
          onTap: onNewVideo!,
        ),
      _QuickAction(
        icon: Icons.edit_outlined,
        label: 'প্রোফাইল এডিট',
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
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider,
              ),
            ),
            child: Column(
              children: [
                Icon(a.icon, color: AppColors.primary, size: 26),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
