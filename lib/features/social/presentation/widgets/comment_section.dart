// lib/features/social/presentation/widgets/comment_section.dart
// সংশোধিত: mention UI, সব notification trigger, localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/comment_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import 'comment_tile.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String? storyId;
  final String? episodeId;
  final String? videoId;
  final String? ownerId;

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
  final _auth = AuthService();
  final _follow = FollowService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<CommentModel> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _replyToId;
  String? _replyToName;

  // Mention
  final List<UserModel> _mentioned = [];
  final _mentionQuery = ValueNotifier<String>('');
  bool _showMentionList = false;

  bool get _isStory => widget.storyId != null;
  bool get _isEpisode => widget.episodeId != null;
  bool get _isVideo => widget.videoId != null;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scroll.dispose();
    _mentionQuery.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (sel.baseOffset < 0) return;

    // শেষ @ থেকে এখন পর্যন্ত query বের করি
    final before = text.substring(0, sel.baseOffset);
    final atIdx = before.lastIndexOf('@');
    if (atIdx < 0) {
      if (_showMentionList) setState(() => _showMentionList = false);
      return;
    }
    // @ এর আগে space বা line start হলে সেটাই mention শুরু
    if (atIdx > 0 && before[atIdx - 1] != ' ' && before[atIdx - 1] != '\n') {
      if (_showMentionList) setState(() => _showMentionList = false);
      return;
    }
    final query = before.substring(atIdx + 1).trim();
    if (query.length > 20) {
      if (_showMentionList) setState(() => _showMentionList = false);
      return;
    }
    _mentionQuery.value = query;
    if (!_showMentionList) setState(() => _showMentionList = true);
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
      final mentionedIds = _mentioned.map((u) => u.id).toList();

      if (_isStory) {
        await _service.addStoryComment(
          storyId: widget.storyId!,
          body: text,
          parentId: _replyToId,
          replyToName: _replyToName,
          mentionedUserIds: mentionedIds,
          postOwnerId: widget.ownerId,
        );
      } else if (_isEpisode) {
        await _service.addEpisodeComment(
          episodeId: widget.episodeId!,
          body: text,
          parentId: _replyToId,
          replyToName: _replyToName,
          mentionedUserIds: mentionedIds,
          postOwnerId: widget.ownerId,
        );
      } else {
        await _service.addVideoComment(
          videoId: widget.videoId!,
          body: text,
          parentId: _replyToId,
          replyToName: _replyToName,
          mentionedUserIds: mentionedIds,
          postOwnerId: widget.ownerId,
        );
      }

      _controller.clear();
      if (!mounted) return;
      setState(() {
        _replyToId = null;
        _replyToName = null;
        _mentioned.clear();
        _showMentionList = false;
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

  // ---------- Mention insert ----------

  void _insertMention(UserModel u) {
    final text = _controller.text;
    final sel = _controller.selection;
    if (sel.baseOffset < 0) return;
    final before = text.substring(0, sel.baseOffset);
    final atIdx = before.lastIndexOf('@');
    if (atIdx < 0) return;
    final after = text.substring(sel.baseOffset);

    final newText = '${text.substring(0, atIdx)}@${u.displayName} $after';
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: atIdx + u.displayName.length + 2,
    );

    if (!_mentioned.any((m) => m.id == u.id)) {
      _mentioned.add(u);
    }
    setState(() {
      _showMentionList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myId = _auth.currentUser?.id;

    return Column(
      children: [
        // হেডার
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                l10n.comments,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                    '${l10n.reply}: ${_replyToName ?? ''}',
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

        // Mention picker
        if (_showMentionList)
          _MentionPicker(
            query: _mentionQuery.value,
            onPick: _insertMention,
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

        // Mentioned users chips (ইনপুটের উপরে)
        if (_mentioned.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _mentioned
                  .map(
                    (u) => Chip(
                      label: Text(
                        u.displayName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      avatar: CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          u.initial,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() {
                        _mentioned.removeWhere((m) => m.id == u.id);
                      }),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
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
                      hintText: l10n.writeComment,
                      helperText: 'টাইপ করুন @ mention করতে',
                      helperStyle: const TextStyle(fontSize: 10),
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

// ---------------- Mention Picker ----------------

class _MentionPicker extends StatefulWidget {
  final String query;
  final void Function(UserModel) onPick;

  const _MentionPicker({
    required this.query,
    required this.onPick,
  });

  @override
  State<_MentionPicker> createState() => _MentionPickerState();
}

class _MentionPickerState extends State<_MentionPicker> {
  final _follow = FollowService();
  final _auth = AuthService();
  List<UserModel> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(covariant _MentionPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _search();
  }

  Future<void> _search() async {
    final q = widget.query.trim();
    setState(() => _loading = true);
    try {
      // query খালি হলে — নিজে যে follow করি তাদের প্রথম ৫
      if (q.isEmpty) {
        final myId = _auth.currentUser?.id;
        if (myId == null) {
          setState(() {
            _results = [];
            _loading = false;
          });
          return;
        }
        final list = await _follow.getFollowing(myId);
        if (!mounted) return;
        setState(() {
          _results = list.take(5).toList();
          _loading = false;
        });
        return;
      }

      // query থাকলে full_name/nickname দিয়ে সার্চ (profiles)
      // আমরা সহজভাবে follow-লিস্ট ফিল্টার করি (কম API call)
      final myId = _auth.currentUser?.id;
      if (myId == null) {
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }
      final list = await _follow.getFollowing(myId);
      final lower = q.toLowerCase();
      final filtered = list.where((u) {
        return u.displayName.toLowerCase().contains(lower) ||
            u.displayNickname.toLowerCase().contains(lower);
      }).take(8).toList();

      if (!mounted) return;
      setState(() {
        _results = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 160,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final u = _results[i];
          return ListTile(
            dense: true,
            leading: CachedAvatar(
              userId: u.id,
              imageUrl: u.avatarUrl,
              name: u.displayName,
              radius: 16,
              tappable: false,
            ),
            title: Text(u.displayName, maxLines: 1),
            subtitle: u.hasNickname
                ? Text(
                    u.displayNickname,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : null,
            onTap: () => widget.onPick(u),
          );
        },
      ),
    );
  }
}
