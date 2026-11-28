// lib/features/auth/presentation/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../routing/route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: isDark ? _bgDark : _bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // লোগো PNG
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
                      color: _brandGreen,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // অ্যাপের নাম
              Text(
                l10n.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                l10n.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 20),

              // Offline Link
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: _brandGreen,
                  ),
                  onPressed: () => context.push(RouteNames.offline),
                  icon: const Icon(
                    Icons.download_done_outlined,
                    size: 20,
                  ),
                  label: Text(l10n.readOfflineStories),
                ),
              ),

              const Spacer(),

              // Login Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

              // Register Button
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brandGreen,
                    side: const BorderSide(
                      color: _brandGreen,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push(RouteNames.register),
                  child: Text(
                    l10n.createAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Footer
              Text(
                l10n.welcomeFooter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryText,
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
