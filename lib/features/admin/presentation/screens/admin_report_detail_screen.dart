// lib/features/admin/presentation/screens/admin_report_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_colors.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const AdminReportDetailScreen({super.key, required this.report});

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  final _service = ReportService();
  bool _busy = false;

  Future<void> _action(String action) async {
    final id = widget.report['id']?.toString();
    if (id == null) return;
    setState(() => _busy = true);
    try {
      if (action == 'reviewed') await _service.markReviewed(id);
      if (action == 'dismiss') await _service.dismiss(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.ok)),
        );
        context.pop();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.report;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.report),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.typeLabel}: ${r['target_type']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  '${l10n.reasonLabel}: ${r['reason']}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${r['target_id']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _busy ? null : () => _action('reviewed'),
            icon: const Icon(Icons.check),
            label: Text(l10n.reviewed),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _busy ? null : () => _action('dismiss'),
            icon: const Icon(Icons.close),
            label: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
