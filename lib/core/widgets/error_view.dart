// lib/core/widgets/error_view.dart
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class ErrorView extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF159447);
  static const Color _dangerColor = Color(0xFFE41E3F);

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorView({
    super.key,
    this.message = '',
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final finalMessage = message.isEmpty ? l10n.somethingWentWrong : message;
    final finalRetry = retryLabel ?? l10n.retry;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: _dangerColor),
            const SizedBox(height: 16),
            Text(
              finalMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: primaryText),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: onRetry,
                child: Text(finalRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
