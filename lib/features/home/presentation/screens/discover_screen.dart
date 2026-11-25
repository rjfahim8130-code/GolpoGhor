// lib/features/home/presentation/screens/discover_screen.dart
// Brand Green + segmented tabs + writing groups

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../routing/route_names.dart';

class DiscoverScreen extends ConsumerWidget {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF242526);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);

  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final videoOn = ref.watch(videoFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                color: isDark ? _cardDark : _cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1),
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
            primaryText: primaryText,
            secondary: secondary,
          ),
          _tile(
            context,
            icon: Icons.local_fire_department_outlined,
            title: l10n.trending,
            subtitle: l10n.mostRead,
            route: RouteNames.trending,
            primaryText: primaryText,
            secondary: secondary,
          ),
          if (videoOn)
            _tile(
              context,
              icon: Icons.videocam_outlined,
              title: l10n.videos,
              subtitle: l10n.shortVideoFeed,
              route: RouteNames.videos,
              primaryText: primaryText,
              secondary: secondary,
            ),

          Divider(height: 32, color: borderColor),

          // Writing groups
          _sectionTitle(l10n.category, secondary),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CategoryCatalog.writingGroups.map((g) {
              return ActionChip(
                backgroundColor: isDark ? _cardDark : _cardLight,
                side: BorderSide(color: borderColor, width: 1),
                label: Text(
                  l10n.t(g),
                  style: TextStyle(color: primaryText),
                ),
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
                  backgroundColor: isDark ? _cardDark : _cardLight,
                  side: BorderSide(color: borderColor, width: 1),
                  label: Text(
                    l10n.t(g),
                    style: TextStyle(color: primaryText),
                  ),
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
    required Color primaryText,
    required Color secondary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? _borderDark : _borderLight;

    return Card(
      elevation: 0,
      color: isDark ? _cardDark : _cardLight,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _brandGreen.withValues(alpha: 0.12),
          child: Icon(icon, color: _brandGreen),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: primaryText),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: secondary)),
        trailing: Icon(Icons.chevron_right, color: secondary),
        onTap: () => context.push(route),
      ),
    );
  }
}
