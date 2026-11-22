// lib/features/reader/presentation/widgets/reader_content.dart
// Colors come from parent (reader theme), NOT app ThemeMode

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/theme/app_colors.dart';

class ReaderContent extends StatelessWidget {
  final List<ContentBlockModel> blocks;
  final double fontScale;
  final Color? textColor;
  final Color? secondaryColor;

  const ReaderContent({
    super.key,
    required this.blocks,
    this.fontScale = 1.0,
    this.textColor,
    this.secondaryColor,
  });

  TextStyle _styleFor(ContentBlockModel b, Color color) {
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
    final l10n = context.l10n;
    final color = textColor ?? const Color(0xFF1B3D2F);
    final secondary = secondaryColor ?? color.withValues(alpha: 0.65);

    if (blocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.noContent,
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
                  memCacheWidth: 900,
                  placeholder: (_, __) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image_outlined, color: secondary),
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: b.style == 'heading1' || b.style == 'heading2' ? 10 : 6,
            left: b.style == 'quote' ? 12 : 0,
          ),
          child: b.style == 'quote'
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(b.text ?? '', style: _styleFor(b, color)),
                )
              : Text(b.text ?? '', style: _styleFor(b, color)),
        );
      }).toList(),
    );
  }
}
