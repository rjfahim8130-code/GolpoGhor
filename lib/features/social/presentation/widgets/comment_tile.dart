// lib/features/social/presentation/widgets/comment_tile.dart
// সংশোধিত: nickname, replyToName + mention display, localization

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';

class CommentTile extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);
  static const Color _warningColor = Color(0xFFF57C00);

  final CommentModel comment;
  final String? myId;
  final bool isReply;
  final VoidCallback onLike;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.myId,
    this.isReply = false,
    required this.onLike,
    this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final isMine = myId != null && myId == comment.userId;
    final displayName = comment.displayAuthorOr(l10n.user);

    return Padding(
      padding: EdgeInsets.fromLTRB(isReply ? 48 : 12, 6, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatar(
            userId: comment.userId,
            imageUrl: comment.authorAvatar,
            name: displayName,
            radius: isReply ? 14 : 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // নাম + সময়
                GestureDetector(
                  onTap: () {
                    if (comment.userId.isNotEmpty) {
                      context.push('${RouteNames.user}/${comment.userId}');
                    }
                  },
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (comment.hasNickname) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· ${comment.authorNickname}',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        TimeAgo.of(context, comment.createdAt),
                        style: TextStyle(fontSize: 11, color: secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // বডি — reply হলে replyToName bold, mention হলে হাইলাইট
                _buildBody(primaryText),

                // Mention indicator
                if (comment.hasMentions && !isReply) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.alternate_email,
                        size: 11,
                        color: _warningColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${comment.mentionedUserIds.length} mention',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),

                // অ্যাকশন
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _brandGreen,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 26),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onLike,
                      child: Text(
                        comment.likeCount > 0
                            ? '${l10n.like} · ${comment.likeCount}'
                            : l10n.like,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (!isReply && onReply != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: _brandGreen,
                          padding: const EdgeInsets.only(left: 12),
                          minimumSize: const Size(0, 26),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onReply,
                        child: Text(
                          l10n.reply,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    if (isMine && onDelete != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 12),
                          minimumSize: const Size(0, 26),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: _dangerColor,
                        ),
                        onPressed: onDelete,
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Color primaryText) {
    final textStyle = TextStyle(
      fontSize: 14,
      height: 1.4,
      color: primaryText,
    );

    if (comment.isReply &&
        comment.replyToName != null &&
        comment.replyToName!.trim().isNotEmpty) {
      return RichText(
        text: TextSpan(
          style: textStyle,
          children: [
            TextSpan(
              text: '${comment.replyToName} ',
              style: const TextStyle(
                color: _brandGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: comment.body),
          ],
        ),
      );
    }

    return Text(comment.body, style: textStyle);
  }
}
