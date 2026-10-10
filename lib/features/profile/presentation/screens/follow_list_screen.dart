import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String mode; // followers | following

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.mode,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final _service = FollowService();
  List<UserModel> _users = [];
  bool _loading = true;
  String? _error;

  bool get _isFollowers => widget.mode == 'followers';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = _isFollowers
          ? await _service.getFollowers(widget.userId)
          : await _service.getFollowing(widget.userId);
      if (!mounted) return;
      setState(() {
        _users = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFollowers ? 'ফলোয়ার' : 'ফলোয়িং'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _users.isEmpty
                  ? EmptyView(
                      icon: Icons.people_outline,
                      title: _isFollowers
                          ? 'কোনো ফলোয়ার নেই'
                          : 'কাউকে ফলো করছেন না',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = _users[i];
                          return ListTile(
                            leading: CachedAvatar(
                              userId: u.id,
                              imageUrl: u.avatarUrl,
                              name: u.displayName,
                              radius: 22,
                            ),
                            title: Text(
                              u.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: u.bio != null && u.bio!.trim().isNotEmpty
                                ? Text(
                                    u.bio!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondary,
                                    ),
                                  )
                                : null,
                            onTap: () =>
                                context.push('${RouteNames.user}/${u.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
