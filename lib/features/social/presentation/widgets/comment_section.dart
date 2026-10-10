import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/comment_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/comment_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import 'comment_tile.dart';

/// কমেন্ট সেকশন — story, episode, video সবখানে
/// তিনটির যেকোনো একটি id দিতে হবে
class CommentSection extends ConsumerStatefulWidget {
  final String? storyId;
  final String? episodeId;
  final String? videoId;
  final String? ownerId; // পোস্টের মালিক (নোটিফিকেশনের জন্য)

  const CommentSection({
    super.key,
    this.storyId,
    this.episodeId,
    this.videoId,
    this.ownerId,
  }) : assert(
          storyId != null || episodeId != null || videoId != null,
          'অন্তত একটি id দিতে হবে',
        );

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _service = CommentService();
  final _notifService = NotificationService();
  final _auth = AuthService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<CommentModel> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _replyToId;
  String? _replyToName;

  bool get _isStory => widget.storyId != null;
  bool get _isEpisode => widget.episodeId != null;
  bool get _isVideo => widget.videoId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<CommentModel> list;
      if (_isStory) {
        list = await _service.getStoryComments(widget.storyId!);
      } else if (_isEpisode) {
        list = await _service.getEpisodeComments(widget.episodeId!);
      } else {
        list = await _service.getVideoComments(widget.videoId!);
      }
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      CommentModel created;
      if (_isStory) {
        created = await _service.addStoryComment(
          storyId: widget.storyId!,
          body: text,
          parentId: _replyToId,
          replyToName: _replyToName,
        );
      } else if (_isEpisode) {
        created = await _service.addEpisodeComment(
          episodeId: widget.episodeId!,
          body: text,
          parentId: _replyToId,
          replyToName: _replyToName,
        );
      } else {
        created = await _service.addVideoComment(
          videoId: widget.videoId!,
          body: text,
          parentId: _replyToId,
          replyToName: _replyToName,
        );
      }

      // নোটিফিকেশন
      final myId = _auth.currentUser?.id;
      final owner = widget.ownerId;
      if (myId != null && owner != null && owner != myId) {
        final type = _replyToId != null ? 'reply' : 'comment';
        final targetType = _isStory
            ? 'story'
            : (_isEpisode ? 'episode' : 'video');
        final targetId =
            widget.storyId ?? widget.episodeId ?? widget.videoId;
        await _notifService.create(
          targetUserId: owner,
          actorId: myId,
          type: type,
          targetType: targetType,
          targetId: targetId,
        );
      }

      _controller.clear();
      if (!mounted) return;
      setState(() {
        _replyToId = null;
        _replyToName = null;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _like(CommentModel c) async {
    try {
      await _service.toggleCommentLike(c.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(CommentModel c) async {
    try {
      if (_isStory) {
        await _service.deleteComment(c.id, storyId: widget.storyId);
      } else if (_isEpisode) {
        await _service.deleteComment(c.id, episodeId: widget.episodeId);
      } else {
        await _service.deleteComment(c.id, videoId: widget.videoId);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  List<CommentModel> get _roots =>
      _comments.where((c) => !c.isReply).toList();

  List<CommentModel> _replies(String parentId) =>
      _comments.where((c) => c.parentId == parentId).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myId = _auth.currentUser?.id;

    return Column(
      children: [
        // হেডার
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text(
                'মন্তব্য',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_comments.length})',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        // reply ব্যানার
        if (_replyToId != null)
          Container(
            width: double.infinity,
            color: AppColors.primary.withValues(alpha: 0.08),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'উত্তর: ${_replyToName ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() {
                    _replyToId = null;
                    _replyToName = null;
                  }),
                ),
              ],
            ),
          ),

        // লিস্ট
        Expanded(
          child: _loading && _comments.isEmpty
              ? const LoadingView()
              : _roots.isEmpty
                  ? const EmptyView(
                      icon: Icons.chat_bubble_outline,
                      title: 'এখনো কোনো মন্তব্য নেই',
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _roots.length,
                      itemBuilder: (_, i) {
                        final c = _roots[i];
                        final replies = _replies(c.id);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CommentTile(
                              comment: c,
                              myId: myId,
                              onLike: () => _like(c),
                              onReply: () {
                                setState(() {
                                  _replyToId = c.id;
                                  _replyToName = c.displayAuthor;
                                });
                              },
                              onDelete: () => _delete(c),
                            ),
                            ...replies.map(
                              (r) => CommentTile(
                                comment: r,
                                myId: myId,
                                isReply: true,
                                onLike: () => _like(r),
                                onDelete: () => _delete(r),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),

        // ইনপুট
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'মন্তব্য লিখুন…',
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
