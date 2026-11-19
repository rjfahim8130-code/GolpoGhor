// lib/features/admin/presentation/widgets/admin_reports_list.dart
// Deep Forest Green + report detail screen push + TimeAgo fix

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../routing/route_names.dart';
import '../screens/admin_report_detail_screen.dart';

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
    final l10n = context.l10n;

    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            l10n.noOpenReports,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

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
              '${l10n.typeLabel}: $type',
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
                  '${l10n.reasonLabel}: $reason',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'ID: $id'
                  '${createdAt != null ? " · ${TimeAgo.of(context, createdAt)}" : ""}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
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
                  _openDetail(context, r);
                }
                await onChanged();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'open',
                  child: Text(l10n.open),
                ),
                PopupMenuItem(
                  value: 'reviewed',
                  child: Text(l10n.reviewed),
                ),
                PopupMenuItem(
                  value: 'dismiss',
                  child: Text(l10n.cancel),
                ),
              ],
            ),
            onTap: () => _openDetail(context, r),
          ),
        );
      }).toList(),
    );
  }

  void _openDetail(BuildContext context, Map<String, dynamic> report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminReportDetailScreen(report: report),
      ),
    );
  }
}
