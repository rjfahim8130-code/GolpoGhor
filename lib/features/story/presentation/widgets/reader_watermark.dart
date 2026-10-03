import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// পাঠকের রিডারে হালকা লোগো — স্ক্রিনশটে ধরা পড়ে, পড়ায় বাধা কম।
class ReaderWatermark extends StatelessWidget {
  const ReaderWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: AppConstants.readerLogoOpacity,
          child: Transform.rotate(
            angle: -0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 120,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
