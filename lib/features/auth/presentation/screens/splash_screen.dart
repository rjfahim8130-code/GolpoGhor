// lib/features/auth/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/network_provider.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../routing/route_names.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF18191A);
  static const Color _brandGreen = Color(0xFF159447);

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      bool online = true;
      try {
        online = await ref
            .read(networkStatusProvider.notifier)
            .check()
            .timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('NETWORK_CHECK_FAILED: $e');
        online = true;
      }
      if (!mounted) return;

      bool onboardingDone = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        onboardingDone = prefs.getBool('onboarding_done') ?? false;
      } catch (e) {
        debugPrint('PREFS_FAILED: $e');
      }
      if (!mounted) return;

      bool loggedIn = false;
      try {
        loggedIn = AuthService().isLoggedIn;
      } catch (e) {
        debugPrint('AUTH_CHECK_FAILED: $e');
        loggedIn = false;
      }
      if (!mounted) return;

      if (!online) {
        context.go(RouteNames.offline);
        return;
      }

      if (!loggedIn) {
        context.go(
          onboardingDone ? RouteNames.welcome : RouteNames.onboarding,
        );
        return;
      }

      try {
        await ref.read(sessionCacheProvider.notifier).load();
        final profile = await AuthService().getMyProfile();
        if (profile != null) {
          await ref.read(sessionCacheProvider.notifier).save(profile);
        }
        try {
          await AdminService().isAdmin();
        } catch (_) {}
      } catch (e) {
        debugPrint('SPLASH_PROFILE_LOAD_FAILED: $e');
      }
      if (!mounted) return;

      context.go(RouteNames.home);
    } catch (e, st) {
      debugPrint('SPLASH_ERROR: $e');
      debugPrint('$st');
      if (!mounted) return;
      context.go(RouteNames.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _bgDark : _bgLight;
    final primaryText =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryText =
        isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.auto_stories_rounded,
                    size: 100,
                    color: _brandGreen,
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _brandGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.loading,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
