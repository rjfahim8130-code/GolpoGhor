// lib/core/widgets/error_view.dart
// সংশোধিত: localization যোগ

import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';

class ErrorView extends StatelessWidget {
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
    final finalMessage = message.isEmpty ? l10n.somethingWentWrong : message;
    final finalRetry = retryLabel ?? l10n.retry;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              finalMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
