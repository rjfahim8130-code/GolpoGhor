import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/theme/app_colors.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  /// followers | following
  final String mode;

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

  bool get _isFollowers => widget.mode == 'followers';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = _isFollowers
          ? await _service.getFollowers(widget.userId)
          : await _service.getFollowing(widget.userId);
      setState(() {
        _users = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isFollowers ? 'ফলোয়ার' : 'ফলোয়িং'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Text(
                    _isFollowers ? 'কোনো ফলোয়ার নেই' : 'কাউকে ফলো করছেন না',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage: u.avatarUrl != null &&
                                  u.avatarUrl!.isNotEmpty
                              ? NetworkImage(u.avatarUrl!)
                              : null,
                          child: u.avatarUrl == null || u.avatarUrl!.isEmpty
                              ? Text(
                                  u.displayName.isNotEmpty
                                      ? u.displayName[0]
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(u.displayName),
                        subtitle: u.username != null
                            ? Text('@${u.username}')
                            : null,
                        onTap: () => context.push('/user/${u.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
