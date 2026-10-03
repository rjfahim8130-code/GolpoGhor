import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/auth_service.dart';

/// Placeholder — ব্যাচ ৩-এ আসল স্ক্রিন দিয়ে রিপ্লেস হবে একই ক্লাস নামে
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$title\n(স্ক্রিন পরের ব্যাচে যোগ হবে)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = AuthService();

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(auth),
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/welcome' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/splash' ||
          loc == '/onboarding';

      if (!loggedIn && !isAuthRoute) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const _SplashGate(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const _PlaceholderPage('অনবোর্ডিং'),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (_, __) => const _PlaceholderPage('ওয়েলকাম / লগইন গেট'),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const _PlaceholderPage('ইমেইল লগইন'),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const _PlaceholderPage('রেজিস্টার'),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (_, __) => const _PlaceholderPage('পাসওয়ার্ড রিসেট'),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (_, __) => const _PlaceholderPage('প্রোফাইল সেটআপ'),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const _PlaceholderPage('হোম'),
      ),
      GoRoute(
        path: '/discover',
        name: 'discover',
        builder: (_, __) => const _PlaceholderPage('আবিষ্কার'),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (_, __) => const _PlaceholderPage('সার্চ'),
      ),
      GoRoute(
        path: '/story/:id',
        name: 'story',
        builder: (_, state) =>
            _PlaceholderPage('গল্প রিডার ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/create-story',
        name: 'create-story',
        builder: (_, __) => const _PlaceholderPage('গল্প তৈরি'),
      ),
      GoRoute(
        path: '/edit-story/:id',
        name: 'edit-story',
        builder: (_, state) =>
            _PlaceholderPage('গল্প এডিট ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/drafts',
        name: 'drafts',
        builder: (_, __) => const _PlaceholderPage('খসড়া'),
      ),
      GoRoute(
        path: '/novel/:id',
        name: 'novel',
        builder: (_, state) =>
            _PlaceholderPage('উপন্যাস ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/create-novel',
        name: 'create-novel',
        builder: (_, __) => const _PlaceholderPage('উপন্যাস তৈরি'),
      ),
      GoRoute(
        path: '/episode/:id',
        name: 'episode',
        builder: (_, state) =>
            _PlaceholderPage('পর্ব রিডার ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/add-episode/:novelId',
        name: 'add-episode',
        builder: (_, state) =>
            _PlaceholderPage('পর্ব যোগ ${state.pathParameters['novelId']}'),
      ),
      GoRoute(
        path: '/edit-episode/:id',
        name: 'edit-episode',
        builder: (_, state) =>
            _PlaceholderPage('পর্ব এডিট ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const _PlaceholderPage('প্রোফাইল'),
      ),
      GoRoute(
        path: '/user/:id',
        name: 'user',
        builder: (_, state) =>
            _PlaceholderPage('ইউজার ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (_, __) => const _PlaceholderPage('প্রোফাইল এডিট'),
      ),
      GoRoute(
        path: '/set-password',
        name: 'set-password',
        builder: (_, __) => const _PlaceholderPage('পাসওয়ার্ড সেট'),
      ),
      GoRoute(
        path: '/my-works',
        name: 'my-works',
        builder: (_, __) => const _PlaceholderPage('আমার লেখা'),
      ),
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (_, __) => const _PlaceholderPage('সংরক্ষিত'),
      ),
      GoRoute(
        path: '/offline',
        name: 'offline',
        builder: (_, __) => const _PlaceholderPage('ডাউনলোড / অফলাইন'),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const _PlaceholderPage('সেটিংস'),
      ),
      GoRoute(
        path: '/trending',
        name: 'trending',
        builder: (_, __) => const _PlaceholderPage('ট্রেন্ডিং'),
      ),
      GoRoute(
        path: '/category/:name',
        name: 'category',
        builder: (_, state) =>
            _PlaceholderPage('ক্যাটাগরি ${state.pathParameters['name']}'),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const _PlaceholderPage('অ্যাডমিন'),
      ),
      GoRoute(
        path: '/legal/:type',
        name: 'legal',
        builder: (_, state) =>
            _PlaceholderPage('লিগ্যাল ${state.pathParameters['type']}'),
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthService auth) {
    auth.authStateChanges.listen((_) => notifyListeners());
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final auth = AuthService();
    if (!auth.isLoggedIn) {
      context.go('/welcome');
      return;
    }
    final needs = await auth.needsProfileSetup();
    if (!mounted) return;
    if (needs) {
      context.go('/profile-setup');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'গল্পঘর',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
