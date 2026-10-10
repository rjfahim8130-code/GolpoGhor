// lib/features/offline/presentation/screens/offline_downloads_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/network_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';

class OfflineDownloadsScreen extends ConsumerStatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  ConsumerState<OfflineDownloadsScreen> createState() =>
      _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState
    extends ConsumerState<OfflineDownloadsScreen> {
  final _service = OfflineService();
  List<OfflineItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.listAll();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(OfflineItem item) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('"${item.title}" ${l10n.offline} থেকে সরবে।'),
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
    await _service.remove(item.id);
    await _load();
  }

  Future<void> _tryOnline() async {
    final online = await ref.read(networkStatusProvider.notifier).check();
    if (!mounted) return;
    if (online) {
      final auth = AuthService();
      context.go(auth.isLoggedIn ? RouteNames.home : RouteNames.welcome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এখনো ইন্টারনেট নেই')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final online = ref.watch(networkStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offline),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(online ? Icons.wifi : Icons.wifi_off),
            tooltip: online ? 'অনলাইনে যান' : 'ইন্টারনেট নেই',
            color: online ? AppColors.success : null,
            onPressed: _tryOnline,
          ),
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.clearAll,
              onPressed: () async {
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
                if (ok == true) {
                  await _service.clearAll();
                  await _load();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : Column(
              children: [
                if (!online)
                  Container(
                    width: double.infinity,
                    color: AppColors.warning.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off,
                            size: 16, color: AppColors.warning),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'আপনি অফলাইনে আছেন — শুধু ডাউনলোড করা কনটেন্ট পড়া যাবে।',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? const EmptyView(
                          icon: Icons.download_done_outlined,
                          title: 'কোনো ডাউনলোড নেই',
                          subtitle:
                              'গল্প বা উপন্যাসের পর্ব ডাউনলোড করলে এখানে দেখতে পাবেন।',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final item = _items[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    item.kind == 'episode'
                                        ? Icons.menu_book_outlined
                                        : Icons.article_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    if (item.subtitle != null)
                                      item.subtitle!,
                                    if (item.authorName != null)
                                      item.authorName!,
                                    '${_fmt(item.savedAt)}',
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(item),
                                ),
                                onTap: () => context.push(
                                  '${RouteNames.offlineReader}/${item.id}',
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
