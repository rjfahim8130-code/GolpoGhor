import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/story_model.dart';
import '../../../../core/theme/app_colors.dart';

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

  void _openAuthor() {
    if (story.authorId.isEmpty) return;
    context.push('/user/${story.authorId}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final desc = story.description.trim();
    final longDesc = desc.length > 90;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // হেডার
            Row(
              children: [
                GestureDetector(
                  onTap: _openAuthor,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: story.authorAvatar != null &&
                            story.authorAvatar!.isNotEmpty
                        ? CachedNetworkImageProvider(story.authorAvatar!)
                        : null,
                    child: story.authorAvatar == null ||
                            story.authorAvatar!.isEmpty
                        ? Text(
                            (story.authorName ?? 'গ')[0],
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _openAuthor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.authorName ?? 'লেখক',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${story.authorFollowerCount} জন ফলোয়ার',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'গল্প',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // শিরোনাম
            Text(
              story.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            // বিবরণ + সি মোর
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
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: (!_expanded && longDesc)
                            ? '${desc.substring(0, 90)}… '
                            : '$desc ',
                      ),
                      if (longDesc)
                        TextSpan(
                          text: _expanded ? 'কম দেখুন' : 'সি মোর',
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
            // ছবি — থাকলেই
            if (story.coverUrl != null && story.coverUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: story.coverUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  placeholder: (_, __) => Container(
                    height: 120,
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 10),
            // স্ট্যাটস + পড়ুন
            Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                const SizedBox(width: 4),
                Text('${story.viewCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
                const SizedBox(width: 12),
                Icon(Icons.favorite_border,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                const SizedBox(width: 4),
                Text('${story.reactionCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
                const SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline,
                    size: 15,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                const SizedBox(width: 4),
                Text('${story.commentCount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: widget.onTap,
                  child: const Text(
                    'পড়ুন',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
