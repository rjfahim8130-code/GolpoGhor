// lib/features/admin/presentation/widgets/admin_content_list.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/story_model.dart';
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

  static const Color _dangerColor = Color(0xFFE41E3F);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final cardBg = isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);

    if (stories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            l10n.noData,
            style: TextStyle(color: secondaryText),
          ),
        ),
      );
    }

    return Column(
      children: stories.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: ListTile(
            title: Text(
              s.title.isEmpty ? l10n.untitled : s.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
            ),
            subtitle: Text(
              '${s.authorName ?? ''} · ${s.isPublished ? l10n.published : l10n.draft} · ${s.viewCount}',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
            trailing: PopupMenuButton<String>(
              color: cardBg,
              icon: Icon(Icons.more_vert, color: primaryText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1),
              ),
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
                  child: Text(l10n.read, style: TextStyle(color: primaryText)),
                ),
                if (s.isPublished)
                  PopupMenuItem(
                    value: 'unpublish',
                    child: Text(
                      l10n.unpublish,
                      style: TextStyle(color: primaryText),
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l10n.delete,
                    style: const TextStyle(color: _dangerColor),
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
