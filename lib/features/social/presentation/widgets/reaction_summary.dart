// lib/features/social/presentation/widgets/reaction_summary.dart
// localized ready

import 'package:flutter/material.dart';

import 'reaction_picker.dart';

/// একাধিক রিঅ্যাকশনের সারসংক্ষেপ
/// যেমন: [👍❤️🔥] ১৭ জন
class ReactionSummary extends StatelessWidget {
  final Map<String, int> counts;
  final double emojiSize;
  final TextStyle? textStyle;

  const ReactionSummary({
    super.key,
    required this.counts,
    this.emojiSize = 14,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final ringColor =
        isDark ? const Color(0xFF18191A) : const Color(0xFFFFFFFF);
    final secondary =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: emojiSize + 10,
          width: (emojiSize + 6) * top.length + 4,
          child: Stack(
            children: List.generate(top.length, (i) {
              return Positioned(
                left: i * (emojiSize + 2),
                child: Container(
                  width: emojiSize + 10,
                  height: emojiSize + 10,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    ReactionPicker.emoji(top[i].key),
                    style: TextStyle(fontSize: emojiSize - 2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$total',
          style: textStyle ??
              TextStyle(
                fontSize: 12,
                color: secondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
