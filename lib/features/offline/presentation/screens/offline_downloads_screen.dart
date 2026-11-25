// lib/features/offline/presentation/screens/offline_downloads_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/network_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/offline_service.dart';
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
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

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
        content: Text('"${item.title}" ${l10n.removeFromOffline}'),
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
    await _service.remove(item.id);
    await _load();
  }

  Future<void> _tryOnline() async {
    final l10n = context.l10n;
    final online = await ref.read(networkStatusProvider.notifier).check();
    if (!mounted) return;
    if (online) {
      final auth = AuthService();
      context.go(auth.isLoggedIn ? RouteNames.home : RouteNames.welcome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.stillOffline)),
      );
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
    final online = ref.watch(networkStatusProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.offline),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(online ? Icons.wifi : Icons.wifi_off),
            tooltip: online ? l10n.goOnline : l10n.noInternet,
            color: online ? _brandGreen : primaryText,
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
                          style: const TextStyle(color: _dangerColor),
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
                    color: isDark
                        ? const Color(0xFF242526)
                        : const Color(0xFFF0F2F5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, size: 16, color: secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.offlineBanner,
                            style: TextStyle(fontSize: 12, color: primaryText),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? EmptyView(
                          icon: Icons.download_done_outlined,
                          title: l10n.noDownloads,
                          subtitle: l10n.noDownloadsHint,
                        )
                      : RefreshIndicator(
                          color: _brandGreen,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: borderColor),
                            itemBuilder: (_, i) {
                              final item = _items[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _brandGreen.withValues(alpha: 0.12),
                                  child: Icon(
                                    item.kind == 'episode'
                                        ? Icons.menu_book_outlined
                                        : Icons.article_outlined,
                                    color: _brandGreen,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: primaryText),
                                ),
                                subtitle: Text(
                                  [
                                    if (item.subtitle != null) item.subtitle!,
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
                                  icon: Icon(Icons.delete_outline,
                                      color: secondary),
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
