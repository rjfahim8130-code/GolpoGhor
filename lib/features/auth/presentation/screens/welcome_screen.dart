// lib/features/auth/presentation/screens/welcome_screen.dart
// লোগো PNG + localization + offline link

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // ============ লোগো PNG ============
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 130,
                  width: 130,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.auto_stories_rounded,
                      size: 110,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ============ অ্যাপের নাম (সবসময় বাংলা) ============
              const Text(
                'গল্পঘর',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // ============ Tagline ============
              Text(
                'বাংলা গল্প, উপন্যাস ও ভিডিওর ঘর',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // ============ Offline Link ============
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push(RouteNames.offline),
                  icon: const Icon(
                    Icons.download_done_outlined,
                    size: 20,
                  ),
                  label: const Text('অফলাইন গল্প পড়ুন'),
                ),
              ),

              const Spacer(),

              // ============ Login Button ============
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => context.push(RouteNames.login),
                  child: Text(
                    l10n.login,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ============ Register Button ============
              SizedBox(
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => context.push(RouteNames.register),
                  child: Text(
                    l10n.createAccount,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ============ Footer ============
              Text(
                'গল্পঘর — বাংলা সাহিত্যের ডিজিটাল ঘর',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
