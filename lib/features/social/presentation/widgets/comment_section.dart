import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/comment_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/comment_service.dart';
import '../../../../core/theme/app_colors.dart';

class CommentSection extends StatefulWidget {
  final String storyId;

  const CommentSection({super.key, required this.storyId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _service = CommentService();
  final _auth = AuthService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<CommentModel> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _replyToId;
  String? _replyToName;

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
      final list = await _service.getStoryComments(widget.storyId);
      setState(() {
        _comments = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.addStoryComment(
        storyId: widget.storyId,
        body: text,
        parentId: _replyToId,
      );
      _controller.clear();
      setState(() {
        _replyToId = null;
        _replyToName = null;
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _like(CommentModel c) async {
    try {
      await _service.toggleCommentLike(c.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _delete(CommentModel c) async {
    try {
      await _service.deleteComment(c.id, storyId: widget.storyId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    context.push('/user/$userId');
  }

  List<CommentModel> get _roots =>
      _comments.where((c) => c.parentId == null).toList();

  List<CommentModel> _replies(String parentId) =>
      _comments.where((c) => c.parentId == parentId).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myId = _auth.currentUser?.id;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text(
                'কমেন্ট',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        if (_replyToId != null)
          Container(
            width: double.infinity,
            color: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('রিপ্লাই: ${_replyToName ?? ''}'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _replyToId = null;
                    _replyToName = null;
                  }),
                ),
              ],
            ),
          ),
        Expanded(
          child: _loading && _comments.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _roots.isEmpty
                  ? Center(
                      child: Text(
                        'এখনো কোনো কমেন্ট নেই',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
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
                            _commentTile(c, myId, isDark, isReply: false),
                            ...replies.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: _commentTile(
                                  r,
                                  myId,
                                  isDark,
                                  isReply: true,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
                    decoration: InputDecoration(
                      hintText: 'কমেন্ট লিখুন…',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
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

  Widget _commentTile(
    CommentModel c,
    String? myId,
    bool isDark, {
    required bool isReply,
  }) {
    return ListTile(
      dense: isReply,
      leading: GestureDetector(
        onTap: () => _openProfile(c.userId),
        child: CircleAvatar(
          radius: isReply ? 14 : 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage:
              c.authorAvatar != null && c.authorAvatar!.isNotEmpty
                  ? NetworkImage(c.authorAvatar!)
                  : null,
          child: c.authorAvatar == null || c.authorAvatar!.isEmpty
              ? Text(
                  (c.authorName ?? 'উ')[0],
                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                )
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => _openProfile(c.userId),
        child: Text(
          c.authorName ?? 'ইউজার',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(c.body, style: const TextStyle(fontSize: 14, height: 1.35)),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _like(c),
                child: Text(
                  c.likeCount > 0 ? 'লাইক ${c.likeCount}' : 'লাইক',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (!isReply)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(left: 12),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      _replyToId = c.id;
                      _replyToName = c.authorName;
                    });
                  },
                  child: const Text('রিপ্লাই', style: TextStyle(fontSize: 12)),
                ),
              if (myId == c.userId)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(left: 12),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () => _delete(c),
                  child: const Text('মুছুন', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
