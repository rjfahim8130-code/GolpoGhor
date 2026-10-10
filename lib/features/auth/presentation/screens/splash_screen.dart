// lib/features/auth/presentation/screens/splash_screen.dart
// সংশোধিত: safe startup, try-catch সব step-এ, slow হলেও crash না

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/network_provider.dart';
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
      // বেশি delay নেই — 300ms
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      // Network check — fail হলেও চলবে (অনলাইন ধরে নাও)
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

      // Prefs — fail হলেও চলবে
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

      // Auth check — fail হলেও চলবে
      bool loggedIn = false;
      try {
        loggedIn = AuthService().isLoggedIn;
      } catch (e) {
        debugPrint('AUTH_CHECK_FAILED: $e');
        loggedIn = false;
      }
      if (!mounted) return;

      // Route decision
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

      // লগইন আছে — cache setup থাকলে home, না থাকলে home-ই (setup পরে)
      if (cachedSetup) {
        context.go(RouteNames.home);
        return;
      }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 72,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            // অ্যাপের নাম সবসময় বাংলায়
            Text(
              'গল্পঘর',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 28),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
