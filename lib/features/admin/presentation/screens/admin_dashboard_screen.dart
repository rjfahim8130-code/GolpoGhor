// lib/features/admin/presentation/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
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
import 'admin_users_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _admin = AdminService();
  final _reportService = ReportService();

  bool _loading = true;
  bool _allowed = false;
  String? _error;
  Map<String, int> _stats = {};
  List> _reports = [];

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

      final results = await Future.wait([
        _admin.stats(),
        _reportService.listOpen().catchError((_) => >[]),
      ]);

      if (!mounted) return;
      setState(() {
        _allowed = true;
        _stats = results[0] as Map<String, int>;
        _reports = results[1] as List>;
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
    final videoOn = ref.watch(videoFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          title: Text(l10n.admin),
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
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          title: Text(l10n.admin),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyView(
          icon: Icons.lock_outline,
          title: l10n.accessDenied,
          subtitle: l10n.adminOnlyScreen,
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          title: Text(l10n.admin),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ErrorView(message: _error!, onRetry: _init),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.adminDashboard),
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
            _sectionHeader(l10n.statistics),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AdminStatsCard(
                  label: l10n.story,
                  value: '${_stats['stories'] ?? 0}',
                  icon: Icons.article_outlined,
                ),
                AdminStatsCard(
                  label: l10n.novel,
                  value: '${_stats['novels'] ?? 0}',
                  icon: Icons.menu_book_outlined,
                ),
                AdminStatsCard(
                  label: l10n.video,
                  value: '${_stats['videos'] ?? 0}',
                  icon: Icons.videocam_outlined,
                  color: AppColors.info,
                ),
                AdminStatsCard(
                  label: l10n.users,
                  value: '${_stats['users'] ?? 0}',
                  icon: Icons.people_outline,
                  color: AppColors.success,
                ),
                AdminStatsCard(
                  label: l10n.comments,
                  value: '${_stats['comments'] ?? 0}',
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.warning,
                ),
                AdminStatsCard(
                  label: l10n.openReports,
                  value: '${_reports.length}',
                  icon: Icons.flag_outlined,
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionHeader(l10n.users),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.people, color: Colors.white, size: 20),
                ),
                title: Text(
                  l10n.users,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${_stats['users'] ?? 0} ${l10n.totalUsers}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionHeader(l10n.featureControl),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              child: SwitchListTile(
                activeColor: AppColors.primary,
                title: Text(l10n.videoFeature),
                subtitle: Text(
                  videoOn ? l10n.videoFeatureDescOn : l10n.videoFeatureDescOff,
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
                          v ? l10n.videoFeatureOn : l10n.videoFeatureOff,
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

            _sectionHeader(l10n.openReports),
            if (_reports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    l10n.noOpenReports,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._reports.map((r) {
                final type = '${r['target_type'] ?? ''}';
                final id = '${r['target_id'] ?? ''}';
                final reason = '${r['reason'] ?? ''}';
                final createdAtRaw = r['created_at']?.toString();
                final createdAt =
                    createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;

                return Card(
                  elevation: 0,
                  color: cardColor,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.danger,
                      child: Icon(Icons.flag, color: Colors.white, size: 18),
                    ),
                    title: Text(
                      '${l10n.typeLabel}: $type',
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
                          '${l10n.reasonLabel}: $reason',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'ID: $id${createdAt != null ? " · ${TimeAgo.of(context, createdAt)}" : ""}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: secondary),
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
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'open', child: Text(l10n.open)),
                        PopupMenuItem(
                          value: 'reviewed',
                          child: Text(l10n.reviewed),
                        ),
                        PopupMenuItem(
                          value: 'dismiss',
                          child: Text(l10n.cancel),
                        ),
                      ],
                    ),
                    onTap: () => _openTarget(type, id),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

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
          Uri(path: RouteNames.videos, queryParameters: {'focus': id}).toString(),
        );
        break;
      case 'profile':
        context.push('${RouteNames.user}/$id');
        break;
    }
  }
}
