// lib/features/reader/presentation/widgets/reader_watermark.dart
// logo_watermark.png সরাসরি ব্যবহার করে
// fallback: logo.png → icon + text

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ReaderWatermark extends StatelessWidget {
  const ReaderWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? Colors.white : AppColors.primary;

    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: 0.14,
          child: Transform.rotate(
            angle: -0.28,
            child: Image.asset(
              'assets/images/logo_watermark.png',
              width: 240,
              fit: BoxFit.contain,
              color: tint,
              colorBlendMode: BlendMode.srcATop,
              errorBuilder: (_, __, ___) {
                // ─── Fallback ১: logo.png ───
                return Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  fit: BoxFit.contain,
                  color: tint,
                  colorBlendMode: BlendMode.srcATop,
                  errorBuilder: (_, __, ___) {
                    // ─── Fallback ২: icon + text ───
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 110,
                          color: tint,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'গল্পঘর',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: tint,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
