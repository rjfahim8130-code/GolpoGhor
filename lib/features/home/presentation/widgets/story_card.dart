// lib/features/home/presentation/widgets/story_card.dart
// সংশোধিত: 'গল্প' এর পাশে ক্যাটাগরি লেবেল সহ সম্পূর্ণ ফাইল

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';

class StoryCard extends StatefulWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  bool _expanded = false;

  StoryModel get story => widget.story;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final desc = story.description.trim();
    final longDesc = desc.length > 90;

    // ক্যাটাগরি নরমাল করে টাইটেল/লেবেল নেওয়া
    final catKey = CategoryCatalog.normalize(story.category);
    final categoryLabel = catKey != null ? l10n.t(catKey) : '';
    
    // "গল্প · ক্যাটাগরি" অথবা শুধু "গল্প"
    final badgeText = categoryLabel.isNotEmpty
        ? '${l10n.story} · $categoryLabel'
        : l10n.story;

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
              Row(
                children: [
                  CachedAvatar(
                    userId: story.authorId,
                    imageUrl: story.authorAvatar,
                    name: story.authorName ?? l10n.author,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (story.authorId.isNotEmpty) {
                          context
                              .push('${RouteNames.user}/${story.authorId}');
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.authorName ?? l10n.author,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${story.authorFollowerCount} ${l10n.followers} · ${TimeAgo.of(context, story.createdAt)}',
                            style: TextStyle(fontSize: 11, color: secondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              Text(
                story.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: longDesc
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: secondary,
                      ),
                      children: [
                        TextSpan(
                          text: (!_expanded && longDesc)
                              ? '${desc.substring(0, 90)}… '
                              : '$desc ',
                        ),
                        if (longDesc)
                          TextSpan(
                            text: _expanded ? l10n.seeLess : l10n.seeMore,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (story.coverUrl != null && story.coverUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: story.coverUrl!,
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
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    TimeAgo.compactOf(context, story.viewCount),
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.favorite_border, size: 16, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    TimeAgo.compactOf(context, story.reactionCount),
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline, size: 15, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    TimeAgo.compactOf(context, story.commentCount),
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
