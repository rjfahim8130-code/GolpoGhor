// lib/features/reader/presentation/widgets/reader_watermark.dart
// CSS-inspired pattern watermark — আরও premium look

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ReaderWatermark extends StatelessWidget {
  const ReaderWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? Colors.white : AppColors.primary;

    return IgnorePointer(
      child: Stack(
        children: [
          // Diagonal repeating lines (CSS-inspired)
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                painter: _WatermarkPainter(color: tint),
              ),
            ),
          ),
          // Center logo watermark
          Center(
            child: Opacity(
              opacity: 0.06,
              child: Transform.rotate(
                angle: -0.28,
                child: Image.asset(
                  'assets/images/logo_watermark.png',
                  width: 240,
                  fit: BoxFit.contain,
                  color: tint,
                  colorBlendMode: BlendMode.srcATop,
                  errorBuilder: (_, __, ___) {
                    return Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      fit: BoxFit.contain,
                      color: tint,
                      colorBlendMode: BlendMode.srcATop,
                      errorBuilder: (_, __, ___) {
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
        ],
      ),
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  final Color color;
  _WatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const spacing = 60.0;
    final diagonal = size.width + size.height;

    for (double i = -size.height; i < diagonal; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
