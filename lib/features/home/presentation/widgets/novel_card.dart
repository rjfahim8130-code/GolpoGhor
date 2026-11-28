// lib/features/home/presentation/widgets/novel_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/services/follow_service.dart';
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
  static const Color _brandGreen = Color(0xFF159447);

  final _follow = FollowService();
  bool _isFollowing = false;
  bool _followBusy = false;
  bool _expanded = false;

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

  NovelModel get novel => widget.novel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final desc = novel.description.trim();
    final longDesc = desc.length > 90;

    final catKey = CategoryCatalog.normalize(novel.category);
    final categoryLabel = catKey != null ? l10n.t(catKey) : '';

    final badgeText =
        categoryLabel.isNotEmpty ? 'উপন্যাস: $categoryLabel' : 'উপন্যাস';
    final me = Supabase.instance.client.auth.currentUser?.id;
    final showFollow =
        me != null && me != novel.authorId && novel.authorId.isNotEmpty;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1),
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
                    radius: 26,
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showFollow) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: _followBusy ? null : _toggleFollow,
                                  child: Icon(
                                    _isFollowing
                                        ? Icons.check_circle
                                        : Icons.add_circle_outline,
                                    size: 16,
                                    color: _brandGreen,
                                  ),
                                ),
                              ],
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _brandGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _brandGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                novel.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: primaryText,
                ),
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap:
                      longDesc ? () => setState(() => _expanded = !_expanded) : null,
                  child: Text.rich(
                    TextSpan(
                      style:
                          TextStyle(fontSize: 13, height: 1.4, color: secondary),
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
                              color: _brandGreen,
                              fontWeight: FontWeight.w600,
                            ),
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
                      placeholder: (_, __) => Container(
                        color: _brandGreen.withValues(alpha: 0.06),
                      ),
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
                  Text(
                    TimeAgo.compactOf(context, novel.viewCount),
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.favorite_border, size: 16, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    TimeAgo.compactOf(context, novel.reactionCount),
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.menu_book_outlined, size: 15, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    '${novel.episodeCount} পর্ব',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isBn ? 'বিস্তারিত' : 'Details',
                    style: const TextStyle(
                      color: _brandGreen,
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
