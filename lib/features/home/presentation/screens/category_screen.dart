// lib/features/home/presentation/screens/category_screen.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../widgets/story_card.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _service = StoryService();
  List<StoryModel> _stories = [];
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
      final list = await _service.getByCategory(widget.category);
      if (!mounted) return;
      setState(() {
        _stories = list;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _stories.isEmpty
                  ? EmptyView(
                      icon: Icons.menu_book_outlined,
                      title: 'এই ক্যাটাগরিতে এখনো গল্প নেই',
                      subtitle: widget.category,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _stories.length,
                        itemBuilder: (_, i) {
                          final s = _stories[i];
                          return StoryCard(
                            story: s,
                            onTap: () => context
                                .push('${RouteNames.story}/${s.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
