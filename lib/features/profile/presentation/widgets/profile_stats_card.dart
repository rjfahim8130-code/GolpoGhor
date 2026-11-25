// lib/features/profile/presentation/widgets/profile_stats_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
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

    final cardBg = isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              context: context,
              value: followerCount,
              label: l10n.followers,
              primaryColor: primaryText,
              secondaryColor: secondaryText,
              onTap: () => context.push(
                '${RouteNames.follows}/$userId/followers',
              ),
            ),
          ),
          _divider(borderColor),
          Expanded(
            child: _statItem(
              context: context,
              value: followingCount,
              label: l10n.following,
              primaryColor: primaryText,
              secondaryColor: secondaryText,
              onTap: () => context.push(
                '${RouteNames.follows}/$userId/following',
              ),
            ),
          ),
          _divider(borderColor),
          Expanded(
            child: _statItem(
              context: context,
              value: totalViews,
              label: l10n.views,
              primaryColor: primaryText,
              secondaryColor: secondaryText,
              onTap: null,
            ),
          ),
          _divider(borderColor),
          Expanded(
            child: _statItem(
              context: context,
              value: totalReactions,
              label: l10n.reactions,
              primaryColor: primaryText,
              secondaryColor: secondaryText,
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
    required Color primaryColor,
    required Color secondaryColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              TimeAgo.compactOf(context, value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: secondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(Color color) {
    return Container(
      width: 1,
      height: 30,
      color: color,
    );
  }
}
