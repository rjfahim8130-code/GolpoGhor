import 'package:flutter/material.dart';

import '../../../../core/services/report_service.dart';
import '../../../../core/theme/app_colors.dart';

/// সব জায়গায় একই রিপোর্ট শিট
class ReportSheet {
  ReportSheet._();

  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
    String title = 'রিপোর্ট',
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
  final String title;

  const _ReportBody({
    required this.targetType,
    required this.targetId,
    required this.title,
  });

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody> {
  final _service = ReportService();
  final _controller = TextEditingController();
  String? _preset;
  bool _sending = false;

  static const _presets = [
    'কপিরাইট চুরি',
    'অশ্লীল বা আপত্তিকর',
    'স্প্যাম বা বিভ্রান্তিকর',
    'হয়রানি বা আক্রমণাত্মক',
    'অন্যান্য',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = [
      if (_preset != null && _preset != 'অন্যান্য') _preset!,
      _controller.text.trim(),
    ].where((e) => e.isNotEmpty).join(' — ');

    if (reason.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কারণ লিখুন বা বেছে নিন')),
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
        const SnackBar(content: Text('রিপোর্ট পাঠানো হয়েছে')),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'কারণ বেছে নিন এবং চাইলে বিস্তারিত লিখুন',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((p) {
              final selected = _preset == p;
              return ChoiceChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                selected: selected,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : null,
                ),
                onSelected: (_) => setState(() => _preset = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'বিস্তারিত কারণ লিখুন…',
              border: OutlineInputBorder(),
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
                : const Text('রিপোর্ট পাঠান'),
          ),
        ],
      ),
    );
  }
}
