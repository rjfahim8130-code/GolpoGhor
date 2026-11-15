// lib/core/widgets/skeleton_loader.dart
// Shimmer skeleton loading — সব screen-এর জন্য reusable

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Base shimmer box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final EdgeInsets? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Story/Novel/Episode card skeleton
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        highlightColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 36, height: 36, radius: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 12),
                      SizedBox(height: 6),
                      SkeletonBox(width: 80, height: 10),
                    ],
                  ),
                ),
                SkeletonBox(width: 60, height: 22, radius: 11),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonBox(width: double.infinity, height: 18),
            const SizedBox(height: 8),
            const SkeletonBox(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const SkeletonBox(width: 200, height: 12),
            const SizedBox(height: 12),
            const SkeletonBox(width: double.infinity, height: 140, radius: 12),
          ],
        ),
      ),
    );
  }
}

/// List skeleton — multiple cards
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}

/// Profile header skeleton
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        highlightColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
        child: Column(
          children: [
            const SkeletonBox(width: 88, height: 88, radius: 44),
            const SizedBox(height: 12),
            const SkeletonBox(width: 160, height: 20),
            const SizedBox(height: 8),
            const SkeletonBox(width: 120, height: 14),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (_) => const Column(
                  children: [
                    SkeletonBox(width: 40, height: 18),
                    SizedBox(height: 4),
                    SkeletonBox(width: 50, height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
