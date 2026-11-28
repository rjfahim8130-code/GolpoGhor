// lib/features/admin/presentation/widgets/admin_feature_toggles.dart
// সংশোধিত: localization

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/video_feature_provider.dart';

class AdminFeatureToggles extends ConsumerWidget {
  const AdminFeatureToggles({super.key});

  static const Color _brandGreen = Color(0xFF159447);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final videoOn = ref.watch(videoFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF242526) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB);
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: SwitchListTile(
        activeColor: _brandGreen,
        title: Text(l10n.videoFeature, style: TextStyle(color: primaryText)),
        subtitle: Text(
          videoOn ? l10n.videoFeatureDescOn : l10n.videoFeatureDescOff,
          style: TextStyle(fontSize: 12, color: secondaryText),
        ),
        secondary: Icon(
          videoOn ? Icons.videocam : Icons.videocam_off,
          color: videoOn ? _brandGreen : secondaryText,
        ),
        value: videoOn,
        onChanged: (v) async {
          try {
            await ref.read(videoFeatureProvider.notifier).setEnabled(v);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  v ? l10n.videoFeatureOn : l10n.videoFeatureOff,
                ),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        },
      ),
    );
  }
}
