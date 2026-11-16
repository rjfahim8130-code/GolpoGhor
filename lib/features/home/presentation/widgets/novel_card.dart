// lib/features/home/presentation/widgets/novel_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';

class NovelCard extends StatefulWidget {
  final NovelModel novel;
  final VoidCallback onTap;

  const NovelCard({super.key, required this.novel, required this.onTap});

  @override
  State<NovelCard> createState() => _NovelCardState();
}

class _NovelCardState extends State<NovelCard> {
  bool _expanded = false;

  NovelModel get novel => widget.novel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final desc = novel.description.trim();
    final longDesc = desc.length > 90;

    final catKey = CategoryCatalog.normalize(novel.category);
    final categoryLabel = catKey != null ? l10n.t(catKey) : '';

    final badgeText = categoryLabel.isNotEmpty ? 'উপন্যাস: $categoryLabel' : 'উপন্যাস';
    final isFollowing = false;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedAvatar(
                    userId: novel.authorId,
                    imageUrl: novel.authorAvatar,
                    name: novel.authorName ?? l10n.author,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (novel.authorId.isNotEmpty) {
                          context.push('${RouteNames.user}/${novel.authorId}');
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  novel.authorName ?? l10n.author,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isFollowing ? Icons.check_circle : Icons.add_circle_outline,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${novel.authorFollowerCount} ${l10n.followers}',
                            style: TextStyle(fontSize: 11, color: secondary),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            TimeAgo.of(context, novel.createdAt),
                            style: TextStyle(fontSize: 11, color: secondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                novel.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: longDesc ? () => setState(() => _expanded = !_expanded) : null,
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 13, height: 1.4, color: secondary),
                      children: [
                        TextSpan(text: (!_expanded && longDesc) ? '${desc.substring(0, 90)}… ' : '$desc '),
                        if (longDesc)
                          TextSpan(
                            text: _expanded ? l10n.seeLess : l10n.seeMore,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (novel.coverUrl != null && novel.coverUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: novel.coverUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (_, __) => Container(color: AppColors.primary.withValues(alpha: 0.06)),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // উপন্যাস কার্ডের বিশেষ ফুটার: সকল পর্বের মোট ভিউ, মোট লাইক, পর্ব সংখ্যা এবং বিস্তারিত/Details বাটন
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: secondary),
                  const SizedBox(width: 4),
                  Text(TimeAgo.compactOf(context, novel.viewCount), style: TextStyle(fontSize: 12, color: secondary)),
                  const SizedBox(width: 10),
                  Icon(Icons.favorite_border, size: 16, color: secondary),
                  const SizedBox(width: 4),
                  Text(TimeAgo.compactOf(context, novel.reactionCount), style: TextStyle(fontSize: 12, color: secondary)),
                  const SizedBox(width: 10),
                  Icon(Icons.menu_book_outlined, size: 15, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    '${novel.episodeCount} পর্ব',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
                  ),
                  const Spacer(),
                  Text(
                    isBn ? 'বিস্তারিত' : 'Details',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
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
