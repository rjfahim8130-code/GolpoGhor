// lib/features/home/presentation/screens/discover_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('কনটেন্ট', secondary),
          _tile(
            context,
            icon: Icons.star_outline,
            title: l10n.popular,
            subtitle: 'বেশি প্রতিক্রিয়া',
            route: RouteNames.popular,
          ),
          _tile(
            context,
            icon: Icons.local_fire_department_outlined,
            title: l10n.trending,
            subtitle: 'সবচেয়ে বেশি পঠিত',
            route: RouteNames.trending,
          ),
          if (videoOn)
            _tile(
              context,
              icon: Icons.videocam_outlined,
              title: l10n.videos,
              subtitle: 'শর্ট ভিডিও ফিড',
              route: RouteNames.videos,
            ),
          const Divider(height: 32),
          _sectionTitle(l10n.category, secondary),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.categories.map((c) {
              return ActionChip(
                label: Text(c),
                onPressed: () => context.push(
                  Uri(
                    path: RouteNames.category,
                    queryParameters: {'name': c},
                  ).toString(),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 32),
          _sectionTitle(l10n.search, secondary),
          _tile(
            context,
            icon: Icons.search,
            title: 'গল্প, উপন্যাস, লেখক বা কোড',
            subtitle: 'যেকোনো কিছু খুঁজুন',
            route: RouteNames.search,
          ),
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
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
