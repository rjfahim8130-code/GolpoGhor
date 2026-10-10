import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// সব জায়গায় একই avatar — ছবি না থাকলে অক্ষর
/// ট্যাপ করলে সরাসরি ইউজার প্রোফাইলে নিয়ে যাবে
class CachedAvatar extends StatelessWidget {
  final String? userId;
  final String? imageUrl;
  final String name;
  final double radius;
  final bool tappable;
  final Color? backgroundColor;
  final Color? textColor;

  const CachedAvatar({
    super.key,
    this.userId,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.tappable = true,
    this.backgroundColor,
    this.textColor,
  });

  void _openProfile(BuildContext context) {
    if (!tappable) return;
    if (userId == null || userId!.isEmpty) return;
    context.push('/user/$userId');
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final initial =
        name.trim().isNotEmpty ? name.trim().substring(0, 1) : '?';

    final bg = backgroundColor ?? AppColors.primary.withValues(alpha: 0.15);
    final fg = textColor ?? AppColors.primary;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage:
          hasImage ? CachedNetworkImageProvider(imageUrl!) : null,
      child: hasImage
          ? null
          : Text(
              initial,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.85,
              ),
            ),
    );

    if (!tappable || userId == null || userId!.isEmpty) return avatar;

    return GestureDetector(
      onTap: () => _openProfile(context),
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}
