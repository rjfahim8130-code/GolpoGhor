// lib/features/admin/presentation/screens/admin_dashboard_screen.dart
// সংশোধিত: localization + মাসিক ইউজার স্ট্যাটস

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
        _error = 'লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final videoOn = ref.watch(videoFeatureProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
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
        appBar: AppBar(
          title: Text(l10n.admin),
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
          title: Text(l10n.admin),
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
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
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
            // ---------------- Stats ----------------
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

            // ---------------- Monthly Users ----------------
            _sectionHeader('মাসিক ইউজার'),
            Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.totalUsers,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_stats['users'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _monthRow(
                      l10n.thisMonthNew,
                      '${_stats['this_month_new'] ?? 0}',
                      AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    _monthRow(
                      l10n.lastMonthNew,
                      '${_stats['last_month_new'] ?? 0}',
                      AppColors.info,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Supabase Free Plan MAU লিমিট: ৫০,০০০ / মাস',
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
