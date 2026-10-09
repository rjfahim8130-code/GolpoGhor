import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/insights_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _service = InsightsService();
  InsightsBundle? _data;
  bool _loading = true;
  bool _videoOn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final videoOn = await VideoService().isVideoFeatureEnabled();
    final data = await _service.loadMine();
    if (!mounted) return;
    setState(() {
      _videoOn = videoOn;
      _data = data;
      _loading = false;
    });
  }

  String _delta(int cur, int prev) {
    if (prev == 0) return cur > 0 ? '+$cur' : '০';
    final d = cur - prev;
    if (d > 0) return '+$d';
    if (d < 0) return '$d';
    return '০';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ইনসাইট'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'লেখা (গল্প · উপন্যাস · পর্ব)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _periodCard(
                    'এই সপ্তাহ',
                    _data!.writingWeek,
                    _delta(
                      _data!.writingWeek.views,
                      _data!.writingPrevWeek.views,
                    ),
                  ),
                  _periodCard(
                    'এই মাস',
                    _data!.writingMonth,
                    _delta(
                      _data!.writingMonth.views,
                      _data!.writingPrevMonth.views,
                    ),
                  ),
                  if (_videoOn) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'ভিডিও',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _periodCard(
                      'এই সপ্তাহ',
                      _data!.videoWeek,
                      _delta(
                        _data!.videoWeek.views,
                        _data!.videoPrevWeek.views,
                      ),
                    ),
                    _periodCard(
                      'এই মাস',
                      _data!.videoMonth,
                      _delta(
                        _data!.videoMonth.views,
                        _data!.videoPrevMonth.views,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'তুলনা: আগের সপ্তাহ/মাসের তুলনায় ভিউ পরিবর্তন। '
                    'বিস্তারিত ইম্প্রেশন হিস্ট্রি পরের আপডেটে আসবে।',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _periodCard(String title, InsightsPeriodStats s, String viewDelta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  'ভিউ $viewDelta',
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
              spacing: 16,
              runSpacing: 8,
              children: [
                _chip('দেখা', '${s.views}'),
                _chip('প্রতিক্রিয়া', '${s.reactions}'),
                _chip('মন্তব্য', '${s.comments}'),
                if (s.saves > 0) _chip('সেভ', '${s.saves}'),
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
