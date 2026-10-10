import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../widgets/admin_stats_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
  final _admin = AdminService();
  final _reportService = ReportService();

  bool _loading = true;
  bool _allowed = false;
  String? _error;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await _admin.isAdmin();
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _allowed = false;
          _loading = false;
        });
        return;
      }

      // stats + reports parallel
      final results = await Future.wait([
        _admin.stats(),
        _reportService.listOpen().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;
      setState(() {
        _allowed = true;
        _stats = results[0] as Map<String, int>;
        _reports = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoOn = ref.watch(videoFeatureProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('অ্যাডমিন'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const LoadingView(),
      );
    }

    if (!_allowed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('অ্যাডমিন'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const EmptyView(
          icon: Icons.lock_outline,
          title: 'অ্যাক্সেস নেই',
          subtitle: 'এই স্ক্রিন শুধু অ্যাডমিনের জন্য।',
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('অ্যাডমিন'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ErrorView(message: _error!, onRetry: _init),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('অ্যাডমিন ড্যাশবোর্ড'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _init,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------- Stats ----------
            const _SectionHeader('পরিসংখ্যান'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AdminStatsCard(
                  label: 'গল্প',
                  value: '${_stats['stories'] ?? 0}',
                  icon: Icons.article_outlined,
                ),
                AdminStatsCard(
                  label: 'উপন্যাস',
                  value: '${_stats['novels'] ?? 0}',
                  icon: Icons.menu_book_outlined,
                ),
                AdminStatsCard(
                  label: 'ভিডিও',
                  value: '${_stats['videos'] ?? 0}',
                  icon: Icons.videocam_outlined,
                  color: AppColors.info,
                ),
                AdminStatsCard(
                  label: 'ইউজার',
                  value: '${_stats['users'] ?? 0}',
                  icon: Icons.people_outline,
                  color: AppColors.success,
                ),
                AdminStatsCard(
                  label: 'কমেন্ট',
                  value: '${_stats['comments'] ?? 0}',
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.warning,
                ),
                AdminStatsCard(
                  label: 'খোলা রিপোর্ট',
                  value: '${_reports.length}',
                  icon: Icons.flag_outlined,
                  color: AppColors.danger,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---------- Feature toggle ----------
            const _SectionHeader('ফিচার কন্ট্রোল'),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                activeColor: AppColors.primary,
                title: const Text('ভিডিও ফিচার'),
                subtitle: Text(
                  videoOn
                      ? 'চালু — সবাই ভিডিও দেখতে ও আপলোড করতে পারবে'
                      : 'বন্ধ — ভিডিও সংক্রান্ত সব লুকানো থাকবে',
                  style: const TextStyle(fontSize: 12),
                ),
                secondary: Icon(
                  videoOn ? Icons.videocam : Icons.videocam_off,
                  color: videoOn ? AppColors.primary : Colors.grey,
                ),
                value: videoOn,
                onChanged: (v) async {
                  try {
                    await ref
                        .read(videoFeatureProvider.notifier)
                        .setEnabled(v);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v ? 'ভিডিও ফিচার চালু' : 'ভিডিও ফিচার বন্ধ',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                },
              ),
            ),
            
            const SizedBox(height: 24),

            // ---------- Reports ----------
            const _SectionHeader('খোলা রিপোর্ট'),
            if (_reports.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'কোনো খোলা রিপোর্ট নেই',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._reports.map((r) {
                final type = '${r['target_type'] ?? ''}';
                final id = '${r['target_id'] ?? ''}';
                final reason = '${r['reason'] ?? ''}';
                final createdAtRaw = r['created_at']?.toString();
                final createdAt = createdAtRaw != null
                    ? DateTime.tryParse(createdAtRaw)
                    : null;

                return Card(
                  elevation: 0,
                  color: cardColor,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.danger,
                      child:
                          Icon(Icons.flag, color: Colors.white, size: 18),
                    ),
                    title: Text(
                      'ধরন: $type',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          'কারণ: $reason',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'ID: $id'
                          '${createdAt != null ? " · ${TimeAgo.bn(createdAt)}" : ""}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        final rid = r['id']?.toString();
                        if (rid == null) return;
                        if (v == 'reviewed') {
                          await _reportService.markReviewed(rid);
                        }
                        if (v == 'dismiss') {
                          await _reportService.dismiss(rid);
                        }
                        if (v == 'open') {
                          _openTarget(type, id);
                        }
                        await _init();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'open',
                          child: Text('খুলুন'),
                        ),
                        PopupMenuItem(
                          value: 'reviewed',
                          child: Text('রিভিউড'),
                        ),
                        PopupMenuItem(
                          value: 'dismiss',
                          child: Text('বাতিল'),
                        ),
                      ],
                    ),
                    onTap: () => _openTarget(type, id),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // ---------- Moderation hint ----------
            const _SectionHeader('মডারেশন'),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'গল্প/ভিডিও মডারেশন আরো ফিচার পরে আসবে। '
                        'এখন রিপোর্ট প্রসেস করতে পারবেন।',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------- Helpers ----------

  void _openTarget(String type, String id) {
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
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
