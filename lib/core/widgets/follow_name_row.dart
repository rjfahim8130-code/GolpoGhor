// lib/core/widgets/follow_name_row.dart
// Avatar + name + optional follow +/- (hide for self / mentions)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/follow_service.dart';
import '../../routing/route_names.dart';
import 'cached_avatar.dart';

class FollowNameRow extends StatefulWidget {
  final String userId;
  final String? imageUrl;
  final String displayName;
  final String? subtitle;
  final double avatarRadius;
  final Color? nameColor;
  final Color? subtitleColor;
  final bool dense;
  /// mention-only name chips must set hideFollow: true
  final bool hideFollow;
  final VoidCallback? onNameTap;

  const FollowNameRow({
    super.key,
    required this.userId,
    required this.displayName,
    this.imageUrl,
    this.subtitle,
    this.avatarRadius = 18,
    this.nameColor,
    this.subtitleColor,
    this.dense = false,
    this.hideFollow = false,
    this.onNameTap,
  });

  @override
  State<FollowNameRow> createState() => _FollowNameRowState();
}

class _FollowNameRowState extends State<FollowNameRow> {
  final _follow = FollowService();
  bool _loading = false;
  bool _isFollowing = false;
  bool _checked = false;

  String? get _myId => Supabase.instance.client.auth.currentUser?.id;

  bool get _isMe {
    final me = _myId;
    return me != null && me == widget.userId;
  }

  bool get _showFollow =>
      !widget.hideFollow &&
      !_isMe &&
      widget.userId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FollowNameRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _checked = false;
      _load();
    }
  }

  Future<void> _load() async {
    if (!_showFollow) {
      setState(() {
        _checked = true;
        _isFollowing = false;
      });
      return;
    }
    try {
      final v = await _follow.isFollowing(widget.userId);
      if (mounted) {
        setState(() {
          _isFollowing = v;
          _checked = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checked = true);
    }
  }

  Future<void> _toggle() async {
    if (_loading || !_showFollow) return;
    setState(() => _loading = true);
    try {
      final next = await _follow.toggleFollow(widget.userId);
      if (mounted) setState(() => _isFollowing = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProfile() {
    if (widget.onNameTap != null) {
      widget.onNameTap!();
      return;
    }
    if (widget.userId.isEmpty) return;
    context.push('${RouteNames.user}/${widget.userId}');
  }

  @override
  Widget build(BuildContext context) {
    final nameStyle = TextStyle(
      color: widget.nameColor ?? Theme.of(context).textTheme.bodyLarge?.color,
      fontWeight: FontWeight.w600,
      fontSize: widget.dense ? 13 : 14,
    );
    final subStyle = TextStyle(
      color: widget.subtitleColor ?? Theme.of(context).textTheme.bodySmall?.color,
      fontSize: widget.dense ? 11 : 12,
    );

    return Row(
      children: [
        GestureDetector(
          onTap: _openProfile,
          child: CachedAvatar(
            userId: widget.userId,
            imageUrl: widget.imageUrl,
            name: widget.displayName,
            radius: widget.avatarRadius,
          ),
        ),
        SizedBox(width: widget.dense ? 8 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: _openProfile,
                      child: Text(
                        widget.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
                    ),
                  ),
                  if (_showFollow && _checked) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _loading ? null : _toggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isFollowing
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline,
                                size: widget.dense ? 18 : 20,
                                color: _isFollowing
                                    ? Colors.green
                                    : (widget.nameColor ?? Colors.green),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                Text(widget.subtitle!, style: subStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
