// lib/features/notification/presentation/screens/notification_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
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
        _error = 'লোড করা যায়নি';
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
              style: const TextStyle(color: AppColors.danger),
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
        // target_type == comment — comment-এর parent target-এ যাবে
        if (n.targetId != null && n.targetId!.isNotEmpty) {
          // আমরা target_type-এ 'comment' হলে নিচের fallback করব
          // পোস্টে যাওয়ার লজিক পরে যোগ হবে
        }
        break;
    }
  }

  String _textFor(NotificationModel n) {
    final name = n.actorDisplayName;
    switch (n.type) {
      case 'like':
        return '$name আপনার কনটেন্টে রিঅ্যাক্ট করেছেন';
      case 'comment':
        return '$name মন্তব্য করেছেন';
      case 'reply':
        return '$name আপনার মন্তব্যের উত্তর দিয়েছেন';
      case 'mention':
        return '$name আপনাকে মেনশন করেছেন';
      case 'follow':
        return '$name আপনাকে ফলো করেছেন';
      default:
        return n.message ?? 'নোটিফিকেশন';
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
        return AppColors.love;
      case 'comment':
        return AppColors.info;
      case 'reply':
        return AppColors.primary;
      case 'mention':
        return AppColors.warning;
      case 'follow':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
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
                  ? const EmptyView(
                      icon: Icons.notifications_none,
                      title: 'কোনো নোটিফিকেশন নেই',
                      subtitle:
                          'লাইক, কমেন্ট বা ফলো পেলে এখানে দেখতে পাবেন।',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          return ListTile(
                            tileColor: n.isRead
                                ? null
                                : AppColors.primary.withValues(alpha: 0.06),
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
                                        color: isDark
                                            ? AppColors.darkBg
                                            : Colors.white,
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
                              _textFor(n),
                              style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              TimeAgo.bn(n.createdAt),
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
