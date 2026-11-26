// lib/features/social/presentation/screens/comment_replies_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/comment_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_view.dart';
import '../widgets/comment_tile.dart';

class CommentRepliesScreen extends ConsumerStatefulWidget {
  final CommentModel parentComment;
  final String? ownerId;

  const CommentRepliesScreen({
    super.key,
    required this.parentComment,
    this.ownerId,
  });

  @override
  ConsumerState<CommentRepliesScreen> createState() => _CommentRepliesScreenState();
}

class _CommentRepliesScreenState extends ConsumerState<CommentRepliesScreen> {
  final _service = CommentService();
  final _auth = AuthService();
  List<CommentModel> _replies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final allReplies = await _service.getReplies(widget.parentComment.id);
      if (!mounted) return;
      setState(() {
        _replies = allReplies;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final primaryText = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        title: Text('${l10n.reply} (${_replies.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                      ),
                    ),
                  ),
                  child: CommentTile(
                    comment: widget.parentComment,
                    myId: _auth.currentUser?.id,
                    onLike: () {},
                    onReply: null,
                  ),
                ),
                Expanded(
                  child: _replies.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noData,
                            style: TextStyle(color: primaryText),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _replies.length,
                          itemBuilder: (context, index) {
                            final reply = _replies[index];
                            return CommentTile(
                              comment: reply,
                              myId: _auth.currentUser?.id,
                              isReply: true,
                              onLike: () async {
                                await _service.toggleCommentLike(reply.id);
                                _load();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
