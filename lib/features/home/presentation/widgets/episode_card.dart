// lib/features/home/presentation/widgets/episode_card.dart
// উপন্যাসের পর্বের কার্ড উইজেট

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';

class EpisodeCard extends StatefulWidget {
  final EpisodeModel episode;
  final VoidCallback onTap;

  const EpisodeCard({
    super.key,
    required this.episode,
    required this.onTap,
  });

  @override
  State<EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<EpisodeCard> {
  EpisodeModel get episode => widget.episode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final episodeTitle = episode.title.isNotEmpty
        ? episode.title
        : '${l10n.episodeLabel} ${episode.chapterNumber}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // হেডার: লেখক অ্যাভাটার, নাম ও টাইম এগো + ব্যাজ (উপন্যাস · পর্ব N)
              Row(
                children: [
                  CachedAvatar(
                    userId: episode.authorId,
                    imageUrl: episode.authorAvatar,
                    name: episode.authorName ?? l10n.author,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (episode.authorId.isNotEmpty) {
                          context.push('${RouteNames.user}/${episode.authorId}');
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode.authorName ?? l10n.author,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            TimeAgo.of(context, episode.createdAt),
                            style: TextStyle(fontSize: 11, color: secondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ব্যাজ: উপন্যাস · পর্ব N
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${l10n.novel} · ${l10n.episode} ${episode.chapterNumber}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // উপন্যাসের নাম (যদি থাকে)
              if (episode.novelTitle != null && episode.novelTitle!.isNotEmpty) ...[
                Text(
                  episode.novelTitle!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],

              // পর্বের টাইটেল
              Text(
                episodeTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              // কভার পিকচার (যদি থাকে)
              if (episode.coverUrl != null && episode.coverUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: episode.coverUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (_, __) => Container(
                        color: AppColors.primary.withValues(alpha: 0.06),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // বটম বার: এই নির্দিষ্ট পর্বের ভিউ, রিঅ্যাকশন ও কমেন্ট মেট্রিক্স + পড়ুন বাটন
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    TimeAgo.compactOf(context, episode.viewCount),
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.favorite_border, size: 16, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    TimeAgo.compactOf(context, episode.reactionCount),
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline, size: 15, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    TimeAgo.compactOf(context, episode.commentCount),
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const Spacer(),
                  Text(
                    l10n.read,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
