import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// রিডারের মাঝখানে হালকা ওয়াটারমার্ক — পড়ায় বাধা দেয় না, স্ক্রিনশটে বোঝা যায়
class ReaderWatermark extends StatelessWidget {
  const ReaderWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? Colors.white : AppColors.primary;

    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: 0.10,
          child: Transform.rotate(
            angle: -0.28,
            child: Image.asset(
              'assets/images/logo_watermark.png',
              width: 220,
              fit: BoxFit.contain,
              color: tint,
              colorBlendMode: BlendMode.srcATop,
              errorBuilder: (_, __, ___) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_rounded, size: 100, color: tint),
                  const SizedBox(height: 8),
                  Text(
                    'গল্পঘর',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: tint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
