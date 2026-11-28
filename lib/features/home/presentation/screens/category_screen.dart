// lib/features/home/presentation/screens/category_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/category_catalog.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../widgets/story_card.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryKey;

  const CategoryScreen({super.key, required this.categoryKey});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

  final _service = StoryService();
  List<StoryModel> _stories = [];
  bool _loading = true;
  String? _error;

  List<CategoryItem> _subCategories = [];
  String? _selectedSubKey;

  @override
  void initState() {
    super.initState();
    _initCategoryData();
  }

  void _initCategoryData() {
    final key = widget.categoryKey;
    if (CategoryCatalog.writingGroups.contains(key)) {
      _subCategories = CategoryCatalog.writingSubsOf(key);
    } else {
      _selectedSubKey = CategoryCatalog.normalize(key);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<StoryModel> list = [];
      if (_selectedSubKey != null) {
        list = await _service.getByCategory(_selectedSubKey!);
      } else if (_subCategories.isNotEmpty) {
        final subKeys = _subCategories.map((e) => e.key).toList();
        list = await _service.getByCategories(subKeys);
      } else {
        list = await _service.getByCategory(widget.categoryKey);
      }

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
    final titleText = l10n.t(widget.categoryKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final chipBg = isDark ? const Color(0xFF242526) : const Color(0xFFF0F2F5);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(titleText),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (_subCategories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l10n.viewAll),
                      selected: _selectedSubKey == null,
                      selectedColor: _brandGreen.withValues(alpha: 0.16),
                      backgroundColor: chipBg,
                      labelStyle: TextStyle(
                        color:
                            _selectedSubKey == null ? _brandGreen : primaryText,
                        fontWeight: _selectedSubKey == null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedSubKey == null
                              ? _brandGreen
                              : borderColor,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() => _selectedSubKey = null);
                        _load();
                      },
                    ),
                  ),
                  ..._subCategories.map((sub) {
                    final selected = _selectedSubKey == sub.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(l10n.t(sub.key)),
                        selected: selected,
                        selectedColor: _brandGreen.withValues(alpha: 0.16),
                        backgroundColor: chipBg,
                        labelStyle: TextStyle(
                          color: selected ? _brandGreen : primaryText,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected ? _brandGreen : borderColor,
                          ),
                        ),
                        onSelected: (_) {
                          setState(() => _selectedSubKey = sub.key);
                          _load();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(
                        message: l10n.t(_error!),
                        onRetry: _load,
                        retryLabel: l10n.retry,
                      )
                    : _stories.isEmpty
                        ? EmptyView(
                            icon: Icons.menu_book_outlined,
                            title: l10n.noStoriesInCategory,
                            subtitle: titleText,
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
                                  onTap: () => context.push(
                                    '${RouteNames.story}/${s.id}',
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
