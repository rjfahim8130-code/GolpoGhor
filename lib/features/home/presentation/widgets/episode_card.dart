// lib/features/home/presentation/widgets/episode_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/services/follow_service.dart';
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
  static const Color _brandGreen = Color(0xFF159447);

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
    final cardColor =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final episodeTitle = episode.title.isNotEmpty
        ? episode.title
        : '${l10n.episodeLabel} ${episode.chapterNumber}';

    final badgeText = '${l10n.novel}: পর্ব ${episode.chapterNumber}';
    final me = Supabase.instance.client.auth.currentUser?.id;
    final showFollow =
        me != null && me != episode.authorId && episode.authorId.isNotEmpty;

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
                    userId: episode.authorId,
                    imageUrl: episode.authorAvatar,
                    name: episode.authorName ?? l10n.author,
                    radius: 26,
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
                            '0 ${l10n.followers}',
                            style: TextStyle(
                              fontSize: 10,
                              color: secondary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            TimeAgo.of(context, episode.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: secondary,
                              height: 1.15,
                            ),
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
              if (episode.novelTitle != null &&
                  episode.novelTitle!.isNotEmpty) ...[
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
              Text(
                episodeTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: primaryText,
                ),
              ),
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
