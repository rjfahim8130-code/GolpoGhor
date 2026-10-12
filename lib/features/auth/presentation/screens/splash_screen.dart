// lib/features/auth/presentation/screens/splash_screen.dart
// লোগো PNG + safe startup + last route restoration

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/network_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/last_route_storage.dart';
import '../../../../routing/route_names.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    try {
      // ছোট delay — UI দেখানোর জন্য
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      // ───── ১. Network check (fail হলেও অনলাইন ধরে নাও) ─────
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

      // ───── ২. Prefs পড়া (fail হলেও চলবে) ─────
      bool onboardingDone = false;
      bool cachedSetup = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        onboardingDone = prefs.getBool('onboarding_done') ?? false;
        cachedSetup = prefs.getBool('profile_setup_done') ?? false;
      } catch (e) {
        debugPrint('PREFS_FAILED: $e');
      }
      if (!mounted) return;

      // ───── ৩. Auth check (fail হলেও চলবে) ─────
      bool loggedIn = false;
      try {
        loggedIn = AuthService().isLoggedIn;
      } catch (e) {
        debugPrint('AUTH_CHECK_FAILED: $e');
        loggedIn = false;
      }
      if (!mounted) return;

      // ───── ৪. Route decision ─────
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

      // লগইন আছে — আগের শেষ রুটে (Last Route) যাওয়ার চেষ্টা করুন
      try {
        final lastRoute = await LastRouteStorage.read();
        if (lastRoute != null && lastRoute.isNotEmpty && lastRoute != RouteNames.splash) {
          if (!mounted) return;
          context.go(lastRoute);
          return;
        }
      } catch (e) {
        debugPrint('LAST_ROUTE_READ_FAILED: $e');
      }

      if (!mounted) return;
      context.go(RouteNames.home);
    } catch (e, st) {
      debugPrint('SPLASH_ERROR: $e');
      debugPrint('$st');
      if (!mounted) return;
      // যেকোনো সমস্যায় welcome — crash না
      context.go(RouteNames.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ============ লোগো PNG ============
              Image.asset(
                'assets/images/logo.png',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.auto_stories_rounded,
                    size: 100,
                    color: AppColors.primary,
                  );
                },
              ),
              const SizedBox(height: 20),

              // ============ অ্যাপের নাম (সবসময় বাংলা) ============
              Text(
                l10n.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // ============ Tagline ============
              Text(
                l10n.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // ============ Loading ============
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.loading,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
