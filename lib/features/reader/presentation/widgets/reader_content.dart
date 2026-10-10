import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/content_block_model.dart';
import '../../../../core/theme/app_colors.dart';

class ReaderContent extends StatelessWidget {
  final List<ContentBlockModel> blocks;
  final double fontScale;

  const ReaderContent({
    super.key,
    required this.blocks,
    this.fontScale = 1.0,
  });

  TextStyle _styleFor(ContentBlockModel b, bool isDark) {
    final baseSize = b.size ??
        switch (b.style) {
          'heading1' => 26.0,
          'heading2' => 20.0,
          'emphasis' => 17.0,
          'quote' => 16.0,
          _ => 16.5,
        };

    final size = baseSize * fontScale;
    final weight = (b.weight == 'bold' ||
            b.style == 'heading1' ||
            b.style == 'heading2' ||
            b.style == 'emphasis')
        ? FontWeight.w700
        : FontWeight.w500;
    final italic = b.italic || b.style == 'quote';
    final color = isDark ? AppColors.darkText : AppColors.lightText;

    switch (b.font) {
      case 'classic':
        return GoogleFonts.notoSerifBengali(
          fontSize: size,
          fontWeight: weight,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          height: 1.75,
          color: color,
        );
      case 'comfort':
        return GoogleFonts.hindSiliguri(
          fontSize: size * 1.05,
          fontWeight: weight,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          height: 1.85,
          color: color,
        );
      default:
        return GoogleFonts.hindSiliguri(
          fontSize: size,
          fontWeight: weight,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          height: 1.75,
          color: color,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (blocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'কোনো কনটেন্ট নেই',
          style: TextStyle(color: secondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks.map((b) {
        if (b.isImage && b.imageUrl != null && b.imageUrl!.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: b.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          );
        }

        final text = b.text ?? '';
        if (text.isEmpty) return const SizedBox.shrink();

        final align = b.align == 'center' ? TextAlign.center : TextAlign.start;

        Widget child = Text(
          text,
          textAlign: align,
          style: _styleFor(b, isDark),
        );

        if (b.style == 'quote') {
          child = Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
            ),
            child: child,
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: b.style == 'heading1' ? 12 : 10,
            top: b.style == 'heading1' ? 8 : 0,
          ),
          child: child,
        );
      }).toList(),
    );
  }
}
