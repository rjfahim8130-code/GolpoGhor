import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// রিডার মাঝখানে হালকা লোগো — পড়ায় বাধা দেয় না, স্ক্রিনশটে বোঝা যায়
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
              width: 200,
              fit: BoxFit.contain,
              color: tint,
              colorBlendMode: BlendMode.srcATop,
              errorBuilder: (_, __, ___) {
                return Image.asset(
                  'assets/images/logo.png',
                  width: 160,
                  fit: BoxFit.contain,
                  color: tint,
                  colorBlendMode: BlendMode.srcATop,
                  errorBuilder: (_, __, ___) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 96, color: tint),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: tint,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
