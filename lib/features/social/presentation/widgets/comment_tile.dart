// lib/features/social/presentation/widgets/comment_tile.dart
// সংশোধিত: nickname, replyToName + mention display

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../routing/route_names.dart';

class CommentTile extends StatelessWidget {
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
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isMine = myId != null && myId == comment.userId;

    return Padding(
      padding: EdgeInsets.fromLTRB(isReply ? 48 : 12, 6, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedAvatar(
            userId: comment.userId,
            imageUrl: comment.authorAvatar,
            name: comment.displayAuthor,
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
                          comment.displayAuthor,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
                        TimeAgo.bn(comment.createdAt),
                        style: TextStyle(fontSize: 11, color: secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // বডি — reply হলে replyToName bold, mention হলে হাইলাইট
                _buildBody(isDark),

                // Mention indicator
                if (comment.hasMentions && !isReply) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.alternate_email,
                        size: 11,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${comment.mentionedUserIds.length} mention',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.warning,
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
                          foregroundColor: AppColors.danger,
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

  Widget _buildBody(bool isDark) {
    final textStyle = TextStyle(
      fontSize: 14,
      height: 1.4,
      color: isDark ? AppColors.darkText : AppColors.lightText,
    );

    // reply হলে "নাম — text" স্টাইল
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
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: comment.body),
          ],
        ),
      );
    }

    // mention highlight — @নাম কে highlight করতে চাইলে
    // এখানে সরল রাখা হয়েছে — পুরো text দেখানো হচ্ছে
    return Text(comment.body, style: textStyle);
  }
}
