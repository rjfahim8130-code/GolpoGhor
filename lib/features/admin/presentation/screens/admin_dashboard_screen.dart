// lib/features/admin/presentation/screens/admin_dashboard_screen.dart (Part 1)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/empty_state.dart';
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
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF242526);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.loadFailed;
        _loading = false;
      });
    }
  }
  // lib/features/admin/presentation/screens/admin_dashboard_screen.dart (Part 2)
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final videoOn = ref.watch(videoFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          foregroundColor: primaryText,
          elevation: 0,
          scrolledUnderElevation: 0,
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
          foregroundColor: primaryText,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(l10n.admin),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
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
          foregroundColor: primaryText,
          elevation: 0,
          scrolledUnderElevation: 0,
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
        foregroundColor: primaryText,
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
        color: _brandGreen,
        onRefresh: _init,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(l10n.statistics, primaryText),
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
                  color: _brandGreen,
                ),
                AdminStatsCard(
                  label: l10n.users,
                  value: '${_stats['users'] ?? 0}',
                  icon: Icons.people_outline,
                  color: _brandGreen,
                ),
                AdminStatsCard(
                  label: l10n.comments,
                  value: '${_stats['comments'] ?? 0}',
                  icon: Icons.chat_bubble_outline,
                  color: secondary,
                ),
                AdminStatsCard(
                  label: l10n.openReports,
                  value: '${_reports.length}',
                  icon: Icons.flag_outlined,
                  color: _dangerColor,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionHeader(l10n.users, primaryText),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _brandGreen,
                  child: Icon(Icons.people, color: Colors.white, size: 20),
                ),
                title: Text(
                  l10n.users,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
                ),
                subtitle: Text(
                  '${_stats['users'] ?? 0} ${l10n.totalUsers}',
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
                trailing: Icon(Icons.chevron_right, color: secondary),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminUsersScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(l10n.monthlyUsers, primaryText),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          color: _brandGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.totalUsers,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_stats['users'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _brandGreen,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: borderColor),
                    _monthRow(
                      l10n.thisMonthNew,
                      '${_stats['this_month_new'] ?? 0}',
                      _brandGreen,
                      primaryText,
                    ),
                    const SizedBox(height: 8),
                    _monthRow(
                      l10n.lastMonthNew,
                      '${_stats['last_month_new'] ?? 0}',
                      secondary,
                      primaryText,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _brandGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: _brandGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.mauLimitNote,
                              style: TextStyle(
                                fontSize: 11,
                                color: secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionHeader(l10n.featureControl, primaryText),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1),
              ),
              child: SwitchListTile(
                activeColor: _brandGreen,
                title: Text(
                  l10n.videoFeature,
                  style: TextStyle(color: primaryText),
                ),
                subtitle: Text(
                  videoOn ? l10n.videoFeatureDescOn : l10n.videoFeatureDescOff,
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
                secondary: Icon(
                  videoOn ? Icons.videocam : Icons.videocam_off,
                  color: videoOn ? _brandGreen : secondary,
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
            _sectionHeader(l10n.openReports, primaryText),
            if (_reports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    l10n.noOpenReports,
                    style: TextStyle(color: secondary),
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
                    side: BorderSide(color: borderColor, width: 1),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: _dangerColor,
                      child: Icon(Icons.flag, color: Colors.white, size: 18),
                    ),
                    title: Text(
                      '${l10n.typeLabel}: $type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
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
                          style: TextStyle(fontSize: 12, color: secondary),
                        ),
                        Text(
                          'ID: $id'
                          '${createdAt != null ? " · ${TimeAgo.of(context, createdAt)}" : ""}',
                          style: TextStyle(
                            fontSize: 10,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      color: cardColor,
                      icon: Icon(Icons.more_vert, color: primaryText),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor, width: 1),
                      ),
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
                        PopupMenuItem(
                          value: 'open',
                          child: Text(l10n.open,
                              style: TextStyle(color: primaryText)),
                        ),
                        PopupMenuItem(
                          value: 'reviewed',
                          child: Text(l10n.reviewed,
                              style: TextStyle(color: primaryText)),
                        ),
                        PopupMenuItem(
                          value: 'dismiss',
                          child: Text(l10n.cancel,
                              style: TextStyle(color: primaryText)),
                        ),
                      ],
                    ),
                    onTap: () => _openTarget(type, id),
                  ),
                );
              }),
            const SizedBox(height: 24),
            _sectionHeader(l10n.moderation, primaryText),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: _brandGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.moderationHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondary,
                        ),
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

  Widget _sectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _monthRow(String label, String value, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: textColor),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
