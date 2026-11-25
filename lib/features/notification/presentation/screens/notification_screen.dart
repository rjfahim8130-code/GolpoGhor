// lib/features/notification/presentation/screens/notification_screen.dart
// ইনবক্স হিসেবে ব্যবহৃত হচ্ছে (l10n.inbox)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

  final _service = NotificationService();
  List<NotificationModel> _items = [];
  bool _loading = true;
  String? _error;

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
      await _service.clearOld();
      final list = await _service.getMine(
        limit: AppConstants.notificationPageSize,
      );
      if (!mounted) return;
      setState(() {
        _items = list;
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

  Future<void> _clearAll() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearAll),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: _dangerColor),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.clearAll();
    await _load();
  }

  void _onTap(NotificationModel n) {
    _service.markRead(n.id);
    final type = n.targetType;
    final id = n.targetId;
    if (id == null || type == null) return;

    switch (type) {
      case 'story':
        context.push('${RouteNames.story}/$id');
        break;
      case 'novel':
        context.push('${RouteNames.novel}/$id');
        break;
      case 'episode':
        context.push('${RouteNames.episode}/$id');
        break;
      case 'video':
        context.push(
          Uri(
            path: RouteNames.videos,
            queryParameters: {'focus': id},
          ).toString(),
        );
        break;
      case 'profile':
        context.push('${RouteNames.user}/$id');
        break;
      case 'comment':
        break;
    }
  }

  String _textFor(BuildContext context, NotificationModel n) {
    final l10n = context.l10n;
    final name = n.actorDisplayName;
    switch (n.type) {
      case 'like':
        return '$name ${l10n.notifReacted}';
      case 'comment':
        return '$name ${l10n.notifCommented}';
      case 'reply':
        return '$name ${l10n.notifReplied}';
      case 'mention':
        return '$name ${l10n.notifMentioned}';
      case 'follow':
        return '$name ${l10n.notifFollowed}';
      default:
        return n.message ?? l10n.notification;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'reply':
        return Icons.reply;
      case 'mention':
        return Icons.alternate_email;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'like':
        return _dangerColor;
      case 'comment':
        return _brandGreen;
      case 'reply':
        return _brandGreen;
      case 'mention':
        return _brandGreen;
      case 'follow':
        return _brandGreen;
      default:
        return _brandGreen;
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
        title: Text(l10n.inbox),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: l10n.clearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? EmptyState(
                      icon: Icons.notifications_none,
                      title: l10n.noNotifications,
                      subtitle: l10n.noNotificationsHint,
                    )
                  : RefreshIndicator(
                      color: _brandGreen,
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: borderColor),
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          return ListTile(
                            tileColor: n.isRead
                                ? null
                                : _brandGreen.withValues(alpha: 0.07),
                            leading: Stack(
                              children: [
                                CachedAvatar(
                                  userId: n.actorId,
                                  imageUrl: n.actorAvatar,
                                  name: n.actorDisplayName,
                                  radius: 22,
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: _colorFor(n.type),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: bg,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      _iconFor(n.type),
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              _textFor(context, n),
                              style: TextStyle(
                                color: primaryText,
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              TimeAgo.of(context, n.createdAt),
                              style: TextStyle(fontSize: 12, color: secondary),
                            ),
                            onTap: () => _onTap(n),
                          );
                        },
                      ),
                    ),
    );
  }
}
