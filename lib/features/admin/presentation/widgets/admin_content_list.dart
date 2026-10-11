// lib/features/admin/presentation/widgets/admin_content_list.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

class AdminContentList extends StatelessWidget {
  final List<StoryModel> stories;
  final Future<void> Function(StoryModel) onUnpublish;
  final Future<void> Function(StoryModel) onDelete;

  const AdminContentList({
    super.key,
    required this.stories,
    required this.onUnpublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (stories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'কোনো কনটেন্ট নেই',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Column(
      children: stories.map((s) {
        return Card(
          elevation: 0,
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              s.title.isEmpty ? '(শিরোনামহীন)' : s.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${s.authorName ?? ''} · ${s.isPublished ? "প্রকাশিত" : "খসড়া"} · ${s.viewCount} দেখা',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'open') {
                  context.push('${RouteNames.story}/${s.id}');
                }
                if (v == 'unpublish') onUnpublish(s);
                if (v == 'delete') onDelete(s);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'open',
                  child: Text(l10n.read),
                ),
                if (s.isPublished)
                  const PopupMenuItem(
                    value: 'unpublish',
                    child: Text('আনপাবলিশ'),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l10n.delete,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
            onTap: () => context.push('${RouteNames.story}/${s.id}'),
          ),
        );
      }).toList(),
    );
  }
}
