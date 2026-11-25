// lib/features/home/presentation/widgets/segmented_tabs.dart

import 'package:flutter/material.dart';

class SegmentedTab extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF159447);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SegmentedTab({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final unselectedText =
        isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: labels.length,
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _brandGreen : unselectedBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _brandGreen : borderColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.white : unselectedText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
