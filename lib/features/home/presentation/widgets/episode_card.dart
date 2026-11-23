// lib/features/home/presentation/widgets/episode_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';

class EpisodeCard extends StatefulWidget {
  final EpisodeModel episode;
  final VoidCallback onTap;

  const EpisodeCard({super.key, required this.episode, required this.onTap});

  @override
  State<EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<EpisodeCard> {
  final _follow = FollowService();
  bool _isFollowing = false;
  bool _followBusy = false;

  EpisodeModel get episode => widget.episode;

  @override
  void initState() {
    super.initState();
    _loadFollow();
  }

  Future<void> _loadFollow() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || me == episode.authorId || episode.authorId.isEmpty) return;
    try {
      final v = await _follow.isFollowing(episode.authorId);
      if (mounted) setState(() => _isFollowing = v);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || me == episode.authorId || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      final next = await _follow.toggleFollow(episode.authorId);
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

    final episodeTitle = episode.title.isNotEmpty
        ? episode.title
        : '${l10n.episodeLabel} ${episode.chapterNumber}';

    final badgeText = '${l10n.novel}: ${l10n.episode} ${episode.chapterNumber}';
    final me = Supabase.instance.client.auth.currentUser?.id;
    final showFollow = me != null && me != episode.authorId && episode.authorId.isNotEmpty;

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
                      userId: episode.authorId,
                      imageUrl: episode.authorAvatar,
                      name: episode.authorName ?? l10n.author,
                      radius: 24,
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    episode.authorName ?? l10n.author,
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
                              TimeAgo.of(context, episode.createdAt),
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
                if (episode.novelTitle != null && episode.novelTitle!.isNotEmpty) ...[
                  Text(
                    episode.novelTitle!,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  episodeTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                ),
                if (episode.coverUrl != null && episode.coverUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: episode.coverUrl!,
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
                    Text(TimeAgo.compactOf(context, episode.viewCount), style: TextStyle(fontSize: 12, color: secondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.favorite_border, size: 16, color: secondary),
                    const SizedBox(width: 4),
                    Text(TimeAgo.compactOf(context, episode.reactionCount), style: TextStyle(fontSize: 12, color: secondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.chat_bubble_outline, size: 16, color: secondary),
                    const SizedBox(width: 4),
                    Text(TimeAgo.compactOf(context, episode.commentCount), style: TextStyle(fontSize: 12, color: secondary)),
                    const Spacer(),
                    Text(
                      l10n.read,
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
