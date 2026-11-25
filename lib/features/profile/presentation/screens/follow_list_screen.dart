// lib/features/profile/presentation/screens/follow_list_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/follow_service.dart';
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
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);

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
        _error = context.l10n.loadFailed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_isFollowers ? l10n.followers : l10n.following),
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
                          ? l10n.noFollowers
                          : l10n.notFollowingAnyone,
                    )
                  : RefreshIndicator(
                      color: _brandGreen,
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: borderColor),
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
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: primaryText,
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
