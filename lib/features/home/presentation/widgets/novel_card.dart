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
import '../../../../core/services/follow_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../routing/route_names.dart';

class NovelCard extends StatefulWidget {
  final NovelModel novel;
  final VoidCallback onTap;

  const NovelCard({super.key, required this.novel, required this.onTap});

  @override
  State<NovelCard> createState() => _NovelCardState();
}

class _NovelCardState extends State<NovelCard> {
  final _follow = FollowService();
  bool _isFollowing = false;
  bool _followBusy = false;
  bool _expanded = false;

  NovelModel get novel => widget.novel;

  @override
  void initState() {
    super.initState();
    _loadFollow();
  }

  Future<void> _loadFollow() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final id = widget.novel.authorId;
    if (me == null || me == id || id.isEmpty) return;
    try {
      final v = await _follow.isFollowing(id);
      if (mounted) setState(() => _isFollowing = v);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    final id = widget.novel.authorId;
    if (me == null || me == id || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      final next = await _follow.toggleFollow(id);
      if (mounted) setState(() => _isFollowing = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final desc = novel.description.trim();
    final longDesc = desc.length > 90;

    final catKey = CategoryCatalog.normalize(novel.category);
    final categoryLabel = catKey != null ? l10n.t(catKey) : '';

    final badgeText = categoryLabel.isNotEmpty ? 'উপন্যাস: $categoryLabel' : 'উপন্যাস';
    final me = Supabase.instance.client.auth.currentUser?.id;
    final showFollow = me != null && me != novel.authorId && novel.authorId.isNotEmpty;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
                      radius: 24,
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (showFollow) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _followBusy ? null : _toggleFollow,
                                    child: Icon(
                                      _isFollowing ? Icons.check_circle : Icons.add_circle_outline,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${novel.authorFollowerCount} ${l10n.followers} · ${TimeAgo.of(context, novel.createdAt)}',
                              style: TextStyle(fontSize: 11, color: secondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
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
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: novel.coverUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                        placeholder: (_, __) => Container(color: AppColors.primary.withValues(alpha: 0.05)),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 16, color: secondary),
                    const SizedBox(width: 4),
                    Text(TimeAgo.compactOf(context, novel.viewCount), style: TextStyle(fontSize: 12, color: secondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.favorite_border, size: 16, color: secondary),
                    const SizedBox(width: 4),
                    Text(TimeAgo.compactOf(context, novel.reactionCount), style: TextStyle(fontSize: 12, color: secondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.menu_book_outlined, size: 16, color: secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${novel.episodeCount} ${isBn ? "পর্ব" : "Episodes"}',
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
      ),
    );
  }
}
