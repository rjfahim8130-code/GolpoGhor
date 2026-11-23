// lib/features/home/presentation/widgets/story_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';

class StoryCard extends StatefulWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const StoryCard({super.key, required this.story, required this.onTap});

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  bool _expanded = false;
  final _follow = FollowService();
  bool _isFollowing = false;
  bool _followBusy = false;

  StoryModel get story => widget.story;

  @override
  void initState() {
    super.initState();
    _loadFollow();
  }

  Future<void> _loadFollow() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || me == story.authorId || story.authorId.isEmpty) return;
    try {
      final v = await _follow.isFollowing(story.authorId);
      if (mounted) setState(() => _isFollowing = v);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || me == story.authorId || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      final next = await _follow.toggleFollow(story.authorId);
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

    final desc = story.description.trim();
    final longDesc = desc.length > 90;

    final catKey = CategoryCatalog.normalize(story.category);
    final categoryLabel = catKey != null ? l10n.t(catKey) : '';
    final badgeText = categoryLabel.isNotEmpty ? 'গল্প: $categoryLabel' : 'গল্প';

    final me = Supabase.instance.client.auth.currentUser?.id;
    final showFollow = me != null && me != story.authorId && story.authorId.isNotEmpty;

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
                // Author Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedAvatar(
                      userId: story.authorId,
                      imageUrl: story.authorAvatar,
                      name: story.authorName ?? l10n.author,
                      radius: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () {
                                    if (story.authorId.isNotEmpty) {
                                      context.push('${RouteNames.user}/${story.authorId}');
                                    }
                                  },
                                  child: Text(
                                    story.authorName ?? l10n.author,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                            '${story.authorFollowerCount} ${l10n.followers} · ${TimeAgo.of(context, story.createdAt)}',
                            style: TextStyle(fontSize: 11, color: secondary),
                          ),
                        ],
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
                
                // Content
                Text(
                  story.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    maxLines: _expanded ? 20 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: secondary, height: 1.4),
                  ),
                  if (longDesc)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _expanded ? l10n.seeLess : l10n.seeMore,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                
                // Footer Stats
                Row(
                  children: [
                    Icon(Icons.remove_red_eye_outlined, size: 16, color: secondary),
                    const SizedBox(width: 4),
                    Text('${story.viewCount}', style: TextStyle(fontSize: 12, color: secondary)),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite_border, size: 16, color: secondary),
                    const SizedBox(width: 4),
                    Text('${story.reactionCount}', style: TextStyle(fontSize: 12, color: secondary)),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline, size: 16, color: secondary),
                    const SizedBox(width: 4),
                    Text('${story.commentCount}', style: TextStyle(fontSize: 12, color: secondary)),
                    const Spacer(),
                    Text(
                      l10n.read,
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
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
