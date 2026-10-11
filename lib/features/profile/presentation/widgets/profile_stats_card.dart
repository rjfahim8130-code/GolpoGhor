// lib/features/profile/presentation/widgets/profile_stats_card.dart
// সংশোধিত: ৪টি stat — ফলোয়ার, ফলোয়িং, ভিউ, রিঅ্যাকশন

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../routing/route_names.dart';

class ProfileStatsCard extends StatelessWidget {
  final String userId;
  final int followerCount;
  final int followingCount;
  final int totalViews;
  final int totalReactions;

  const ProfileStatsCard({
    super.key,
    required this.userId,
    required this.followerCount,
    required this.followingCount,
    this.totalViews = 0,
    this.totalReactions = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              context: context,
              value: followerCount,
              label: l10n.followers,
              secondary: secondary,
              onTap: () => context.push(
                '${RouteNames.follows}/$userId/followers',
              ),
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _statItem(
              context: context,
              value: followingCount,
              label: l10n.following,
              secondary: secondary,
              onTap: () => context.push(
                '${RouteNames.follows}/$userId/following',
              ),
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _statItem(
              context: context,
              value: totalViews,
              label: l10n.views,
              secondary: secondary,
              onTap: null,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _statItem(
              context: context,
              value: totalReactions,
              label: l10n.reactions,
              secondary: secondary,
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required BuildContext context,
    required int value,
    required String label,
    required Color secondary,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              TimeAgo.compactOf(context, value),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }
}
