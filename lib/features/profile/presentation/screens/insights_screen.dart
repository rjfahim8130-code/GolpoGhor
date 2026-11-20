// lib/features/profile/presentation/screens/insights_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/insights_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  final _service = InsightsService();
  InsightsBundle? _data;
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
      final data = await _service.loadMine();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  String _delta(int cur, int prev) {
    if (prev == 0) return cur > 0 ? '+$cur' : '0';
    final d = cur - prev;
    if (d > 0) return '+$d';
    if (d < 0) return '$d';
    return '0';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final videoOn = ref.watch(videoFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insights),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionHeader(l10n.insightsWritingHeader),
                      _periodCard(
                        l10n.thisWeek,
                        _data!.writingWeek,
                        _delta(
                          _data!.writingWeek.views,
                          _data!.writingPrevWeek.views,
                        ),
                      ),
                      _periodCard(
                        l10n.thisMonth,
                        _data!.writingMonth,
                        _delta(
                          _data!.writingMonth.views,
                          _data!.writingPrevMonth.views,
                        ),
                      ),
                      if (videoOn) ...[
                        const SizedBox(height: 24),
                        _sectionHeader(l10n.video),
                        _periodCard(
                          l10n.thisWeek,
                          _data!.videoWeek,
                          _delta(
                            _data!.videoWeek.views,
                            _data!.videoPrevWeek.views,
                          ),
                        ),
                        _periodCard(
                          l10n.thisMonth,
                          _data!.videoMonth,
                          _delta(
                            _data!.videoMonth.views,
                            _data!.videoPrevMonth.views,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        l10n.insightsCompareHint,
                        style: TextStyle(fontSize: 12, color: secondary),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _periodCard(
    String title,
    InsightsPeriodStats s,
    String viewDelta,
  ) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${l10n.views} $viewDelta',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _chip(l10n.seen, '${s.views}'),
                _chip(l10n.reactions, '${s.reactions}'),
                _chip(l10n.comments, '${s.comments}'),
                if (s.saves > 0) _chip(l10n.saves, '${s.saves}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
