// lib/features/profile/presentation/screens/insights_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/insights_service.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF242526);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);

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
    final bg = isDark ? _bgDark : _bgLight;
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
                  color: _brandGreen,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionHeader(l10n.insightsWritingHeader, primaryText),
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
                        _sectionHeader(l10n.video, primaryText),
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

  Widget _sectionHeader(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
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
    final cardColor = isDark ? _cardDark : _cardLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${l10n.views} $viewDelta',
                  style: const TextStyle(
                    color: _brandGreen,
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
                _chip(l10n.seen, '${s.views}', primaryText),
                _chip(l10n.reactions, '${s.reactions}', primaryText),
                _chip(l10n.comments, '${s.comments}', primaryText),
                if (s.saves > 0) _chip(l10n.saves, '${s.saves}', primaryText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _brandGreen,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
      ],
    );
  }
}
