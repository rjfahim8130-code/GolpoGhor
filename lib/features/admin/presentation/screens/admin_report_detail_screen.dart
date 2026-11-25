// lib/features/admin/presentation/screens/admin_report_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/report_service.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const AdminReportDetailScreen({super.key, required this.report});

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF242526);
  static const Color _borderLight = Color(0xFFE4E6EB);
  static const Color _borderDark = Color(0xFF3E4042);
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

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
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final cardBg = isDark ? _cardDark : _cardLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final primaryText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final r = widget.report;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
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
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: _dangerColor),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.typeLabel}:${r['target_type']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
                Divider(height: 20, color: borderColor),
                Text(
                  '${l10n.reasonLabel}:${r['reason']}',
                  style: TextStyle(fontSize: 13, color: primaryText),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${r['target_id']}',
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandGreen,
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
              foregroundColor: _dangerColor,
              side: const BorderSide(color: _dangerColor),
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
