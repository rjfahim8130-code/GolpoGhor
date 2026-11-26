// lib/features/auth/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    try {
      // ১.৫ সেকেন্ড শুধু লোগো দেখাবে
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      bool online = true;
      try {
        online = await ref
            .read(networkStatusProvider.notifier)
            .check()
            .timeout(const Duration(seconds: 4));
      } catch (_) {
        online = true;
      }
      if (!mounted) return;

      bool onboardingDone = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        onboardingDone = prefs.getBool('onboarding_done') ?? false;
      } catch (_) {}
      if (!mounted) return;

      bool loggedIn = false;
      try {
        loggedIn = AuthService().isLoggedIn;
      } catch (_) {
        loggedIn = false;
      }
      if (!mounted) return;

      if (!online) {
        context.go(RouteNames.offline);
        return;
      }

      if (!loggedIn) {
        context.go(onboardingDone ? RouteNames.welcome : RouteNames.onboarding);
        return;
      }

      try {
        await ref.read(sessionCacheProvider.notifier).load();
        final profile = await AuthService().getMyProfile();
        if (profile != null) {
          await ref.read(sessionCacheProvider.notifier).save(profile);
        }
        await AdminService().isAdmin();
      } catch (_) {}
      
      if (!mounted) return;
      context.go(RouteNames.home);
    } catch (e) {
      if (!mounted) return;
      context.go(RouteNames.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18191A) : const Color(0xFFFFFFFF),
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 150,
          width: 150,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.auto_stories_rounded, 
              size: 120, 
              color: Color(0xFF159447),
            );
          },
        ),
      ),
    );
  }
}
