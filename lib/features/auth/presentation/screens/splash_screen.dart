import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/network_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routing/route_names.dart';

/// হালকা splash — দ্রুত রাউটিং
/// অফলাইন হলে সরাসরি /offline
/// অনলাইন হলে session/onboarding চেক
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final online = await ref.read(networkStatusProvider.notifier).check();

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final auth = AuthService();

    if (!mounted) return;

    // ১) অফলাইন — সোজা offline লিস্টে
    if (!online) {
      context.go(RouteNames.offline);
      return;
    }

    // ২) অনলাইন — auth চেক
    if (!auth.isLoggedIn) {
      context.go(onboardingDone ? RouteNames.welcome : RouteNames.onboarding);
      return;
    }

    // ৩) লগইন আছে — profile setup চেক (cache first)
    final cachedSetup = prefs.getBool('profile_setup_done') ?? false;
    if (cachedSetup) {
      context.go(RouteNames.home);
      return;
    }

    // ৪) cache নেই — সরাসরি home; background-এ পেজ load হয়ে যাবে
    // (profile set check আর করছি না — হালকা রাখতে)
    context.go(RouteNames.home);
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
            Text(
              'গল্পঘর',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
