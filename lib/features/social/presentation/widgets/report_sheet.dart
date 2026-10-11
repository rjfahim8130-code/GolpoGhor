// lib/features/social/presentation/widgets/report_sheet.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_colors.dart';

class ReportSheet {
  ReportSheet._();

  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
    String? title,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ReportBody(
        targetType: targetType,
        targetId: targetId,
        title: title,
      ),
    );
  }
}

class _ReportBody extends StatefulWidget {
  final String targetType;
  final String targetId;
  final String? title;

  const _ReportBody({
    required this.targetType,
    required this.targetId,
    this.title,
  });

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody> {
  final _service = ReportService();
  final _controller = TextEditingController();
  String? _presetKey;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _presetKeys(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.reportReasonCopyright,
      l10n.reportReasonObscene,
      l10n.reportReasonSpam,
      l10n.reportReasonHarassment,
      l10n.reportReasonOther,
    ];
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final presets = _presetKeys(context);
    final reason = [
      if (_presetKey != null && _presetKey != presets.last) _presetKey!,
      _controller.text.trim(),
    ].where((e) => e.isNotEmpty).join(' — ');

    if (reason.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportEnterReason)),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await _service.submit(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final presets = _presetKeys(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title ?? l10n.report,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.pickReasonHint,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((p) {
              final selected = _presetKey == p;
              return ChoiceChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                selected: selected,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : null,
                ),
                onSelected: (_) => setState(() => _presetKey = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: l10n.detailedReasonHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.sendReport),
          ),
        ],
      ),
    );
  }
}
