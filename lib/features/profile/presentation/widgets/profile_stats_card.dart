import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

/// প্রোফাইলের Stats — ফলোয়ার · ফলোয়িং · পোস্ট
/// প্রতিটি tap-এ respective স্ক্রিনে যাবে
class ProfileStatsCard extends StatelessWidget {
  final String userId;
  final int followerCount;
  final int followingCount;
  final int postCount;

  const ProfileStatsCard({
    super.key,
    required this.userId,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
  });

  @override
  Widget build(BuildContext context) {
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
              value: followerCount,
              label: 'ফলোয়ার',
              secondary: secondary,
              onTap: () => context.push(
                '${RouteNames.follows}/$userId/followers',
              ),
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _statItem(
              value: followingCount,
              label: 'ফলোয়িং',
              secondary: secondary,
              onTap: () => context.push(
                '${RouteNames.follows}/$userId/following',
              ),
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _statItem(
              value: postCount,
              label: 'পোস্ট',
              secondary: secondary,
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
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
              _compact(value),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 34,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }

  String _compact(int n) {
    if (n < 1000) return '$n';
    if (n < 100000) return '${(n / 1000).toStringAsFixed(1)}K';
    if (n < 10000000) return '${(n / 100000).toStringAsFixed(1)}L';
    return '${(n / 10000000).toStringAsFixed(1)}Cr';
  }
}
