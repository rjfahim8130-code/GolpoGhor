import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/story_model.dart';
import '../../../../core/services/story_service.dart';
import '../widgets/story_card.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final _service = StoryService();
  List<StoryModel> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getTrending(limit: 40);
      setState(() {
        _stories = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ট্রেন্ডিং'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? const Center(child: Text('এখনো ট্রেন্ডিং নেই'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _stories.length,
                    itemBuilder: (_, i) {
                      final s = _stories[i];
                      return StoryCard(
                        story: s,
                        onTap: () => context.push('/story/${s.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
