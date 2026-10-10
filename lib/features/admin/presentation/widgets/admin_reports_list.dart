import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../routing/route_names.dart';

/// অ্যাডমিন প্যানেলে খোলা রিপোর্ট লিস্ট
class AdminReportsList extends StatelessWidget {
  final List<Map<String, dynamic>> reports;
  final ReportService service;
  final Future<void> Function() onChanged;

  const AdminReportsList({
    super.key,
    required this.reports,
    required this.service,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'কোনো খোলা রিপোর্ট নেই',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Column(
      children: reports.map((r) {
        final type = '${r['target_type'] ?? ''}';
        final id = '${r['target_id'] ?? ''}';
        final reason = '${r['reason'] ?? ''}';
        final createdAtRaw = r['created_at']?.toString();
        final createdAt = createdAtRaw != null
            ? DateTime.tryParse(createdAtRaw)
            : null;

        return Card(
          elevation: 0,
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.danger,
              child: Icon(Icons.flag, color: Colors.white, size: 18),
            ),
            title: Text(
              'ধরন: $type',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'কারণ: $reason',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'ID: $id'
                  '${createdAt != null ? " · ${TimeAgo.bn(createdAt)}" : ""}',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                final rid = r['id']?.toString();
                if (rid == null) return;
                if (v == 'reviewed') {
                  await service.markReviewed(rid);
                }
                if (v == 'dismiss') {
                  await service.dismiss(rid);
                }
                if (v == 'open') {
                  _openTarget(context, type, id);
                }
                await onChanged();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'open', child: Text('খুলুন')),
                PopupMenuItem(
                  value: 'reviewed',
                  child: Text('রিভিউড'),
                ),
                PopupMenuItem(
                  value: 'dismiss',
                  child: Text('বাতিল'),
                ),
              ],
            ),
            onTap: () => _openTarget(context, type, id),
          ),
        );
      }).toList(),
    );
  }

  void _openTarget(BuildContext context, String type, String id) {
    switch (type) {
      case 'story':
        context.push('${RouteNames.story}/$id');
        break;
      case 'novel':
        context.push('${RouteNames.novel}/$id');
        break;
      case 'episode':
        context.push('${RouteNames.episode}/$id');
        break;
      case 'video':
        context.push(
          Uri(
            path: RouteNames.videos,
            queryParameters: {'focus': id},
          ).toString(),
        );
        break;
      case 'profile':
        context.push('${RouteNames.user}/$id');
        break;
    }
  }
}
