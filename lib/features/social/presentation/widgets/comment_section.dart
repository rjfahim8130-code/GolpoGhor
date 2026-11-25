// lib/features/social/presentation/widgets/comment_section.dart (Part 1)
// সংশোধিত: mention UI, সব notification trigger, localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/comment_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/comment_service.dart';
import '../../../../core/services/follow_service.dart';
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
          'needAtLeastOneId',
        );

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  static const Color _brandGreen = Color(0xFF159447);

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

  String _translateError(BuildContext context, Object e) {
    final raw = e.toString();
    final key = raw.replaceAll('Exception: ', '').trim();
    final l10n = context.l10n;
    return l10n.t(key);
  }

  void _onTextChanged() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (sel.baseOffset < 0) return;

    final before = text.substring(0, sel.baseOffset);
    final atIdx = before.lastIndexOf('@');
    if (atIdx < 0) {
      if (_showMentionList) setState(() => _showMentionList = false);
      return;
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translateError(context, e))),
      );
    }
  }

  List<CommentModel> get _roots =>
      _comments.where((c) => !c.isReply).toList();

  List<CommentModel> _replies(String parentId) =>
      _comments.where((c) => c.parentId == parentId).toList();

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
  // lib/features/social/presentation/widgets/comment_section.dart (Part 2)
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final inputFill =
        isDark ? const Color(0xFF242526) : const Color(0xFFF0F2F5);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final myId = _auth.currentUser?.id;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                l10n.comments,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_comments.length})',
                style: TextStyle(fontSize: 13, color: secondaryText),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _brandGreen,
                  ),
                ),
            ],
          ),
        ),
        if (_replyToId != null)
          Container(
            width: double.infinity,
            color: _brandGreen.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.reply}: ${_replyToName ?? ''}',
                    style: TextStyle(fontSize: 12, color: primaryText),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: secondaryText),
                  onPressed: () => setState(() {
                    _replyToId = null;
                    _replyToName = null;
                  }),
                ),
              ],
            ),
          ),
        if (_showMentionList)
          _MentionPicker(
            query: _mentionQuery.value,
            onPick: _insertMention,
          ),
        Expanded(
          child: _loading && _comments.isEmpty
              ? const LoadingView()
              : _roots.isEmpty
                  ? EmptyView(
                      icon: Icons.chat_bubble_outline,
                      title: l10n.noComments,
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
                                  _replyToName =
                                      c.displayAuthorOr(l10n.user);
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
                      backgroundColor: inputFill,
                      side: BorderSide(color: borderColor),
                      label: Text(
                        u.displayNameOr(l10n.user),
                        style: TextStyle(fontSize: 11, color: primaryText),
                      ),
                      avatar: CircleAvatar(
                        radius: 10,
                        backgroundColor: _brandGreen.withValues(alpha: 0.15),
                        child: Text(
                          u.initial,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _brandGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      deleteIcon: Icon(Icons.close,
                          size: 14, color: secondaryText),
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
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      hintText: l10n.writeComment,
                      hintStyle: TextStyle(color: secondaryText),
                      helperText: l10n.mentionHint,
                      helperStyle:
                          TextStyle(fontSize: 10, color: secondaryText),
                      isDense: true,
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderColor, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: _brandGreen, width: 1.5),
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
                    backgroundColor: _brandGreen,
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
  static const Color _brandGreen = Color(0xFF159447);

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
      final myId = _auth.currentUser?.id;
      if (myId == null) {
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }
      final list = await _follow.getFollowing(myId);
      if (q.isEmpty) {
        if (!mounted) return;
        setState(() {
          _results = list.take(5).toList();
          _loading = false;
        });
        return;
      }
      final lower = q.toLowerCase();
      final filtered = list
          .where((u) =>
              u.displayName.toLowerCase().contains(lower) ||
              u.displayNickname.toLowerCase().contains(lower))
          .take(8)
          .toList();

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
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final surface =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _brandGreen,
              ),
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: surface,
        border: Border.symmetric(
          horizontal: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final u = _results[i];
          return ListTile(
            dense: true,
            leading: CachedAvatar(
              userId: u.id,
              imageUrl: u.avatarUrl,
              name: u.displayNameOr(l10n.user),
              radius: 16,
              tappable: false,
            ),
            title: Text(
              u.displayNameOr(l10n.user),
              maxLines: 1,
              style: TextStyle(color: primaryText),
            ),
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
