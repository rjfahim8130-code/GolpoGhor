import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/story_model.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _admin = AdminService();
  final _reportService = ReportService();
  
  bool _loading = true;
  bool _allowed = false;
  bool _videoOn = false; // ভিডিও ফিচারের স্টেট
  Map<String, int> _stats = {};
  List<StoryModel> _stories = [];
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final ok = await _admin.isAdmin();
    if (!ok) {
      setState(() {
        _allowed = false;
        _loading = false;
      });
      return;
    }
    final stats = await _admin.stats();
    final videoOn = await _admin.getVideoFeatureEnabled();
    final stories = await _admin.recentStories();
    
    List<Map<String, dynamic>> reports = [];
    try {
      reports = await _reportService.listOpen();
    } catch (_) {
      reports = [];
    }

    setState(() {
      _allowed = true;
      _stats = stats;
      _videoOn = videoOn;
      _stories = stories;
      _reports = reports;
      _loading = false;
    });
  }

  Future<void> _unpublish(StoryModel s) async {
    await _admin.unpublishStory(s.id);
    await _init();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আনপাবলিশ করা হয়েছে')),
      );
    }
  }

  Future<void> _delete(StoryModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মুছে ফেলবেন?'),
        content: Text(s.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('মুছুন')),
        ],
      ),
    );
    if (ok != true) return;
    await _admin.deleteStory(s.id);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
        body: const Center(child: Text('অ্যাক্সেস নেই')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('অ্যাডমিন ড্যাশবোর্ড'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _init),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _init,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statCard('গল্প', '${_stats['stories'] ?? 0}'),
                _statCard('উপন্যাস', '${_stats['novels'] ?? 0}'),
                _statCard('ইউজার', '${_stats['users'] ?? 0}'),
                _statCard('কমেন্ট', '${_stats['comments'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('ভিডিও ফিচার'),
                subtitle: Text(
                  _videoOn
                      ? 'চালু — ফিড, আপলোড, এনগেজমেন্ট সব'
                      : 'বন্ধ — ভিডিও সংক্রান্ত সব লুকানো',
                ),
                value: _videoOn,
                activeColor: AppColors.primary,
                onChanged: (v) async {
                  try {
                    await _admin.setVideoFeatureEnabled(v);
                    setState(() => _videoOn = v);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            v ? 'ভিডিও ফিচার চালু' : 'ভিডিও ফিচার বন্ধ',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
              ),
            ),
            if (_reports.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'খোলা রিপোর্ট',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._reports.map((r) {
                final type = '${r['target_type'] ?? ''}';
                final id = '${r['target_id'] ?? ''}';
                final reason = '${r['reason'] ?? ''}';
                return Card(
                  child: ListTile(
                    title: Text('ধরন: $type', maxLines: 1),
                    subtitle: Text(
                      'কারণ: $reason\nআইডি: $id',
                      maxLines: 3,
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
                        await _init();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'reviewed', child: Text('রিভিউড')),
                        PopupMenuItem(value: 'dismiss', child: Text('বাতিল')),
                      ],
                    ),
                    onTap: () {
                      if (type == 'story') context.push('/story/$id');
                      if (type == 'episode') context.push('/episode/$id');
                      if (type == 'novel') context.push('/novel/$id');
                      if (type == 'video') context.push('/videos');
                    },
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            const Text(
              'সাম্প্রতিক গল্প (মডারেশন)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._stories.map((s) {
              return Card(
                child: ListTile(
                  title: Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${s.authorName ?? ''} · ${s.isPublished ? "প্রকাশিত" : "খসড়া"} · ${s.viewCount} দেখা',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'open') context.push('/story/${s.id}');
                      if (v == 'unpublish') _unpublish(s);
                      if (v == 'delete') _delete(s);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'open', child: Text('খুলুন')),
                      if (s.isPublished)
                        const PopupMenuItem(
                          value: 'unpublish',
                          child: Text('আনপাবলিশ'),
                        ),
                      const PopupMenuItem(value: 'delete', child: Text('মুছুন')),
                    ],
                  ),
                  onTap: () => context.push('/story/${s.id}'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(label),
        ],
      ),
    );
  }
}
