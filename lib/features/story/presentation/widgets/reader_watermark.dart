import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

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
            angle: -0.35,
            child: Image.asset(
              'assets/images/logo_watermark.png',
              width: 180,
              fit: BoxFit.contain,
              color: isDark ? Colors.white : AppColors.primary,
              colorBlendMode: BlendMode.srcATop,
              errorBuilder: (_, __, ___) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 100,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
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
