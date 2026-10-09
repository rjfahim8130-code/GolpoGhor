import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/comment_model.dart';
import '../../../../core/services/comment_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/theme/app_colors.dart';

class VideoCommentSheet {
  static Future<void> show(BuildContext context, {required String videoId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _VideoCommentBody(videoId: videoId),
    );
  }
}

class _VideoCommentBody extends StatefulWidget {
  final String videoId;
  const _VideoCommentBody({required this.videoId});

  @override
  State<_VideoCommentBody> createState() => _VideoCommentBodyState();
}

class _VideoCommentBodyState extends State<_VideoCommentBody> {
  final _service = CommentService();
  final _follow = FollowService();
  final _ctrl = TextEditingController();
  List<CommentModel> _items = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getVideoComments(widget.videoId);
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.addVideoComment(videoId: widget.videoId, body: text);
      _ctrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'মন্তব্য',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(child: Text('এখনো কোনো মন্তব্য নেই'))
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final c = _items[i];
                            return ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  if (c.userId.isNotEmpty) {
                                    context.push('/user/${c.userId}');
                                  }
                                },
                                child: CircleAvatar(
                                  backgroundImage: c.userAvatar != null &&
                                          c.userAvatar!.isNotEmpty
                                      ? CachedNetworkImageProvider(c.userAvatar!)
                                      : null,
                                  child: c.userAvatar == null ||
                                          c.userAvatar!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (c.userId.isNotEmpty) {
                                          context.push('/user/${c.userId}');
                                        }
                                      },
                                      child: Text(
                                        c.userName ?? 'ইউজার',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: AppColors.primary,
                                    ),
                                    onPressed: () async {
                                      try {
                                        await _follow.toggleFollow(c.userId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('ফলো আপডেট'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text('$e')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('ফলো', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                              subtitle: Text(c.body),
                            );
                          },
                        ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: const InputDecoration(
                          hintText: 'মন্তব্য লিখুন…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
