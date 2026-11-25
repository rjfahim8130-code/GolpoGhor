// lib/features/admin/presentation/widgets/admin_reports_list.dart
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/utils/time_ago.dart';
import '../screens/admin_report_detail_screen.dart';

class AdminReportsList extends StatelessWidget {
  final List> reports;
  final ReportService service;
  final Future<void> Function() onChanged;

  const AdminReportsList({
    super.key,
    required this.reports,
    required this.service,
    required this.onChanged,
  });

  static const Color _dangerColor = Color(0xFFE41E3F);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            l10n.noOpenReports,
            style: TextStyle(color: secondaryText),
          ),
        ),
      );
    }

    return Column(
      children: reports.map((r) {
        final type = '${r['target_type'] ?? ''}';
        final id = '${r['target_id'] ?? ''}';
        final reason = '${r['reason'] ?? ''}';
        final createdAtRaw = r['created_at']?.toString();
        final createdAt =
            createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;

        return Card(
          elevation: 0,
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: _dangerColor,
              child: Icon(Icons.flag, color: Colors.white, size: 18),
            ),
            title: Text(
              '${l10n.typeLabel}: $type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryText,
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
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
                Text(
                  'ID: $id'
                  '${createdAt != null ? " · ${TimeAgo.of(context, createdAt)}" : ""}',
                  style: TextStyle(
                    fontSize: 10,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              color: cardColor,
              icon: Icon(Icons.more_vert, color: primaryText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1),
              ),
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
                  child: Text(l10n.open, style: TextStyle(color: primaryText)),
                ),
                PopupMenuItem(
                  value: 'reviewed',
                  child:
                      Text(l10n.reviewed, style: TextStyle(color: primaryText)),
                ),
                PopupMenuItem(
                  value: 'dismiss',
                  child: Text(l10n.cancel, style: TextStyle(color: primaryText)),
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
