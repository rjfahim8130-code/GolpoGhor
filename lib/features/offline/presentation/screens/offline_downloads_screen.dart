import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/network_check.dart';

class OfflineDownloadsScreen extends StatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  State<OfflineDownloadsScreen> createState() => _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends State<OfflineDownloadsScreen> {
  final _service = OfflineService();
  List<OfflineStoryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.listAll();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _delete(OfflineStoryItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মুছে ফেলবেন?'),
        content: Text('"${item.title}" অফলাইন থেকে সরবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.remove(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('অফলাইন ডাউনলোড'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // অনলাইনে যাওয়ার বাটন
          IconButton(
            icon: const Icon(Icons.wifi),
            tooltip: 'অনলাইন চেষ্টা',
            onPressed: () async {
              final online = await NetworkCheck.isOnline();
              if (!context.mounted) return;
              if (online) {
                final auth = AuthService();
                context.go(auth.isLoggedIn ? '/home' : '/welcome');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('এখনো নেট নেই')),
                );
              }
            },
          ),
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('সব মুছবেন?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('না'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('হ্যাঁ'),
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
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_done_outlined,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'কোনো ডাউনলোড নেই',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'গল্প পড়ার সময় ডাউনলোড চাপলে এখানে সেভ হবে। নেট ছাড়াই পড়া যাবে।',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.article_outlined,
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
                            if (item.authorName != null) item.authorName!,
                            'সেভ: ${_fmt(item.savedAt)}',
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(item),
                        ),
                        onTap: () => context.push('/offline-story/${item.id}'),
                      );
                    },
                  ),
                ),
    );
  }

  String _fmt(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
