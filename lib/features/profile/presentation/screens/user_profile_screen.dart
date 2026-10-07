import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/theme/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;

  const UserProfileScreen({super.key, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = AuthService();
  final _followService = FollowService();
  UserModel? _user;
  bool _loading = true;
  bool _isMe = true;
  bool _following = false;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final myId = _auth.currentUser?.id;
      final id = widget.userId ?? myId;
      _isMe = id != null && id == myId;
      if (id == null) {
        setState(() => _loading = false);
        return;
      }
      final p = await _auth.getProfile(id);
      bool following = false;
      if (!_isMe && p != null) {
        following = await _followService.isFollowing(p.id);
      }
      setState(() {
        _user = p;
        _following = following;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final u = _user;
    if (u == null || _isMe) return;
    setState(() => _followBusy = true);
    try {
      final on = await _followService.toggleFollow(u.id);
      final refreshed = await _auth.getProfile(u.id);
      setState(() {
        _following = on;
        if (refreshed != null) _user = refreshed;
        _followBusy = false;
      });
    } catch (e) {
      setState(() => _followBusy = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগআউট?'),
        content: const Text('অ্যাকাউন্ট থেকে বেরিয়ে যাবেন?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('লগআউট'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _auth.signOut();
    if (mounted) context.go('/welcome');
  }

  Future<void> _copyCode() async {
    final code = _user?.inviteCode ?? _user?.username;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোড কপি হয়েছে')),
      );
    }
  }

  Future<void> _shareProfile() async {
    final u = _user;
    if (u == null) return;
    final code = u.inviteCode ?? u.username ?? '';
    await Share.share(
      '${u.displayName} — গল্পঘরে ফলো করুন\nকোড: $code\n#গল্পঘর',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: widget.userId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                )
              : null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final u = _user;
    if (u == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('প্রোফাইল পাওয়া যায়নি')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isMe ? 'প্রোফাইল' : u.displayName),
        leading: widget.userId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          if (_isMe) ...[
            IconButton(
              tooltip: 'লিখুন',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.article_outlined),
                          title: const Text('নতুন গল্প'),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/create-story');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          title: const Text('নতুন উপন্যাস'),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push('/create-novel');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage:
                    u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                        ? NetworkImage(u.avatarUrl!)
                        : null,
                child: u.avatarUrl == null || u.avatarUrl!.isEmpty
                    ? Text(
                        u.displayName.isNotEmpty ? u.displayName[0] : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              u.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (u.username != null)
              Text(
                '@${u.username}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            if (u.bio != null && u.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(u.bio!, textAlign: TextAlign.center, style: const TextStyle(height: 1.4)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => context.push('/follows/${u.id}/followers'),
                  child: _stat('${u.followerCount}', 'ফলোয়ার'),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () => context.push('/follows/${u.id}/following'),
                  child: _stat('${u.followingCount}', 'ফলোয়িং'),
                ),
              ],
            ),
            if (!_isMe) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _following ? Colors.grey.shade600 : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _followBusy ? null : _toggleFollow,
                  child: _followBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_following ? 'আনফলো' : 'ফলো'),
                ),
              ),
            ],
            if (u.inviteCode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('আমার কোড', style: TextStyle(fontSize: 12)),
                          Text(
                            u.inviteCode!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(onPressed: _copyCode, icon: const Icon(Icons.copy)),
                    IconButton(
                      onPressed: _shareProfile,
                      icon: const Icon(Icons.share_outlined),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_isMe) ...[
              _menuTile(Icons.edit_outlined, 'প্রোফাইল এডিট',
                  () => context.push('/edit-profile')),
              _menuTile(Icons.lock_outline, 'পাসওয়ার্ড সেট / পরিবর্তন',
                  () => context.push('/set-password')),
              _menuTile(Icons.article_outlined, 'আমার লেখা',
                  () => context.push('/my-works')),
              _menuTile(Icons.bookmark_outline, 'সংরক্ষিত',
                  () => context.push('/saved')),
              _menuTile(Icons.drafts_outlined, 'খসড়া',
                  () => context.push('/drafts')),
              _menuTile(Icons.download_outlined, 'অফলাইন ডাউনলোড',
                  () => context.push('/offline')),
              if (u.isAdmin)
                _menuTile(Icons.admin_panel_settings_outlined, 'অ্যাডমিন',
                    () => context.push('/admin')),
              Consumer(
                builder: (context, ref, child) {
                  final themeMode = ref.watch(themeModeProvider);
                  String subtitle;
                  IconData icon;

                  if (themeMode == ThemeMode.dark) {
                    subtitle = 'ডার্ক মোড';
                    icon = Icons.dark_mode;
                  } else if (themeMode == ThemeMode.light) {
                    subtitle = 'লাইট মোড';
                    icon = Icons.light_mode;
                  } else {
                    subtitle = 'সিস্টেম';
                    icon = Icons.brightness_auto;
                  }

                  return _menuTile(
                    icon,
                    'থিম পরিবর্তন ($subtitle)',
                    () {
                      final current = ref.read(themeModeProvider);
                      if (current == ThemeMode.system) {
                        ref.read(themeModeProvider.notifier).state = ThemeMode.light;
                      } else if (current == ThemeMode.light) {
                        ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
                      } else {
                        ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                      }
                    },
                  );
                },
              ),
              const Divider(height: 32),
              _menuTile(Icons.logout, 'লগআউট', _logout, danger: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: danger ? Colors.red : null),
      title: Text(title, style: TextStyle(color: danger ? Colors.red : null)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
