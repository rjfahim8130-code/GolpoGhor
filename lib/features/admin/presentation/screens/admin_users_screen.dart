// lib/features/admin/presentation/screens/admin_users_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _service = AdminService();
  final _search = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _service.recentUsers(limit: 50);
      if (!mounted) return;
      setState(() {
        _users = users;
        _filtered = users;
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

  void _filter() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _users);
      return;
    }
    setState(() {
      _filtered = _users.where((u) {
        final name = u.displayName.toLowerCase();
        final nick = u.displayNickname.toLowerCase();
        return name.contains(q) || nick.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.users),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? EmptyState(
                              icon: Icons.people_outline,
                              title: l10n.noData,
                            )
                          : ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final u = _filtered[i];
                                return ListTile(
                                  leading: CachedAvatar(
                                    userId: u.id,
                                    imageUrl: u.avatarUrl,
                                    name: u.displayName,
                                    radius: 20,
                                    tappable: false,
                                  ),
                                  title: Text(u.displayNameOr(l10n.user)),
                                  subtitle: u.hasNickname
                                      ? Text('@${u.displayNickname}')
                                      : null,
                                  trailing: u.isAdmin
                                      ? const Icon(Icons.shield,
                                          color: Colors.orange, size: 18)
                                      : null,
                                  onTap: () => context.push(
                                    '${RouteNames.user}/${u.id}',
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
