// lib/features/home/presentation/screens/popular_screen.dart
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

class PopularScreen extends StatefulWidget {
  const PopularScreen({super.key});

  @override
  State<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends State<PopularScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

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
      final list = await _service.getPopular(limit: 40);
      if (!mounted) return;
      setState(() {
        _stories = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'loadFailed';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.popular),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(
                  message: l10n.t(_error!),
                  onRetry: _load,
                  retryLabel: l10n.retry,
                )
              : _stories.isEmpty
                  ? EmptyView(
                      icon: Icons.star_outline,
                      title: l10n.noPopularYet,
                    )
                  : RefreshIndicator(
                      color: _brandGreen,
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
