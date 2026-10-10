import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'reaction_picker.dart';

/// একাধিক রিঅ্যাকশনের সারসংক্ষেপ
/// যেমন: [👍❤️🔥]  ১৭ জন
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

    // সবচেয়ে বেশি ৩টি টাইপ দেখাব
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // overlapping emoji circle
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
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBg
                          : AppColors.lightBg,
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
