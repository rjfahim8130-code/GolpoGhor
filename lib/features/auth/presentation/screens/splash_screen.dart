// lib/features/auth/presentation/screens/splash_screen.dart
// লোগো PNG + safe startup + session cache & profile preload (সংশোধিত)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/network_provider.dart';
import '../../../../core/providers/session_cache_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
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

      // ───── ১. Network check ─────
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

      // ───── ২. Prefs পড়া ─────
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

      // ───── ৩. Auth check ─────
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

      // লগইন থাকলে হোম পেজে যাওয়ার আগে সেশন ক্যাশ ও প্রফাইল প্রি-লোড করুন (অ্যাভাটার দ্রুত দেখানোর জন্য)
      try {
        await ref.read(sessionCacheProvider.notifier).load();
        // এখানে fetchMyProfile()-এর পরিবর্তে সঠিক মেথড getMyProfile() ব্যবহার করা হয়েছে[span_2](start_span)[span_2](end_span)
        final profile = await AuthService().getMyProfile();
        if (profile != null) {
          await ref.read(sessionCacheProvider.notifier).save(profile);
        }
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

              // ============ অ্যাপের নাম ============
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
