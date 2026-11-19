// lib/features/home/presentation/screens/discover_screen.dart
// Deep Forest Green + segmented tabs + writing groups

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final videoOn = ref.watch(videoFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discover),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search bar (tap → search screen)
          GestureDetector(
            onTap: () => context.push(RouteNames.search),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: secondary),
                  const SizedBox(width: 10),
                  Text(
                    l10n.searchHint,
                    style: TextStyle(fontSize: 14, color: secondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Explore section
          _sectionTitle(l10n.content, secondary),
          _tile(
            context,
            icon: Icons.star_outline,
            title: l10n.popular,
            subtitle: l10n.mostReactions,
            route: RouteNames.popular,
          ),
          _tile(
            context,
            icon: Icons.local_fire_department_outlined,
            title: l10n.trending,
            subtitle: l10n.mostRead,
            route: RouteNames.trending,
          ),
          if (videoOn)
            _tile(
              context,
              icon: Icons.videocam_outlined,
              title: l10n.videos,
              subtitle: l10n.shortVideoFeed,
              route: RouteNames.videos,
            ),

          const Divider(height: 32),

          // Writing groups
          _sectionTitle(l10n.category, secondary),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CategoryCatalog.writingGroups.map((g) {
              return ActionChip(
                label: Text(l10n.t(g)),
                onPressed: () => context.push(
                  '${RouteNames.category}?key=$g',
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Video groups (if enabled)
          if (videoOn) ...[
            _sectionTitle(l10n.videos, secondary),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CategoryCatalog.videoGroups.map((g) {
                return ActionChip(
                  label: Text(l10n.t(g)),
                  onPressed: () {
                    context.push(
                      Uri(
                        path: RouteNames.videoSearch,
                        queryParameters: {'q': l10n.t(g)},
                      ).toString(),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, Color secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
