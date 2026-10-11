// lib/features/video/presentation/widgets/video_ad_banner.dart
// ব্যানার বিজ্ঞাপনের জন্য ফাঁকা জায়গা
// সংশোধিত: localization

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class VideoAdBanner extends StatelessWidget {
  final double height;
  final String? imageUrl;
  final String? text;
  final VoidCallback? onTap;

  const VideoAdBanner({
    super.key,
    this.height = 60,
    this.imageUrl,
    this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null && text == null) {
      return SizedBox(height: height);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
          image: imageUrl != null
              ? DecorationImage(
                  image: CachedNetworkImageProvider(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: text != null
            ? Text(
                text!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
    );
  }
}

/// জায়গা রাখার helper
class VideoAdSpace extends StatelessWidget {
  final double height;
  const VideoAdSpace({super.key, this.height = 60});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      height: height,
      color: Colors.transparent,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          l10n.advertisement,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}
