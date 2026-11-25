// lib/features/home/presentation/widgets/story_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/follow_service.dart';
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
  static const Color _brandGreen = Color(0xFF159447);

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
    final cardColor =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final desc = story.description.trim();
    final longDesc = desc.length > 90;

    final catKey = CategoryCatalog.normalize(story.category);
    final categoryLabel = catKey != null ? l10n.t(catKey) : '';
    final badgeText = categoryLabel.isNotEmpty ? 'গল্প: $categoryLabel' : 'গল্প';

    final me = Supabase.instance.client.auth.currentUser?.id;
    final showFollow =
        me != null && me != story.authorId && story.authorId.isNotEmpty;

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
                    userId: story.authorId,
                    imageUrl: story.authorAvatar,
                    name: story.authorName ?? l10n.author,
                    radius: 26,
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
                                    context.push(
                                      '${RouteNames.user}/${story.authorId}',
                                    );
                                  }
                                },
                                child: Text(
                                  story.authorName ?? l10n.author,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryText,
                                  ),
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
                          '${story.authorFollowerCount} ${l10n.followers}',
                          style: TextStyle(fontSize: 11, color: secondary),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          TimeAgo.of(context, story.createdAt),
                          style: TextStyle(fontSize: 11, color: secondary),
                        ),
                      ],
                    ),
                  ),
                  if (badgeText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _brandGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
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
              const SizedBox(height: 10),
              Text(
                story.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: primaryText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  desc,
                  maxLines: _expanded ? 20 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: secondary, height: 1.35),
                ),
                if (longDesc)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _expanded ? l10n.seeLess : l10n.seeMore,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _brandGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.remove_red_eye_outlined, size: 14, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    '${story.viewCount}',
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.favorite_border, size: 14, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    '${story.reactionCount}',
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline, size: 14, color: secondary),
                  const SizedBox(width: 4),
                  Text(
                    '${story.commentCount}',
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                  const Spacer(),
                  Text(
                    l10n.read,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _brandGreen,
                      fontWeight: FontWeight.w600,
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
