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
    final bg = isDark ?
