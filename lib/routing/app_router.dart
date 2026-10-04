import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/auth_service.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/home/presentation/screens/category_list_screen.dart';
import '../features/home/presentation/screens/home_feed_screen.dart';
import '../features/offline/presentation/screens/offline_downloads_screen.dart';
import '../features/offline/presentation/screens/offline_story_reader_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/my_works_screen.dart';
import '../features/profile/presentation/screens/saved_stories_screen.dart';
import '../features/profile/presentation/screens/set_password_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/user_profile_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/story/presentation/screens/create_story_screen.dart';
import '../features/story/presentation/screens/drafts_screen.dart';
import '../features/story/presentation/screens/story_reader_screen.dart';

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
            '$title\n(স্ক্রিন পরের ব্যাচে)',
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

      if (!loggedIn && !isAuthRoute && loc != '/profile-setup') {
        return '/welcome';
      }
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
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeFeedScreen(),
      ),
      GoRoute(
        path: '/discover',
        name: 'discover',
        builder: (_, __) => const _PlaceholderPage('আবিষ্কার'),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/story/:id',
        name: 'story',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StoryReaderScreen(storyId: id);
        },
      ),
      GoRoute(
        path: '/create-story',
        name: 'create-story',
        builder: (_, __) => const CreateStoryScreen(),
      ),
      GoRoute(
        path: '/edit-story/:id',
        name: 'edit-story',
        builder: (_, state) =>
            _PlaceholderPage('এডিট ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/drafts',
        name: 'drafts',
        builder: (_, __) => const DraftsScreen(),
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
            _PlaceholderPage('পর্ব ${state.pathParameters['id']}'),
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
        builder: (_, __) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        name: 'user',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return UserProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/set-password',
        name: 'set-password',
        builder: (_, __) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: '/my-works',
        name: 'my-works',
        builder: (_, __) => const MyWorksScreen(),
      ),
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (_, __) => const SavedStoriesScreen(),
      ),
      GoRoute(
        path: '/offline',
        name: 'offline',
        builder: (_, __) => const OfflineDownloadsScreen(),
      ),
      GoRoute(
        path: '/offline-story/:id',
        name: 'offline-story',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OfflineStoryReaderScreen(storyId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/trending',
        name: 'trending',
        builder: (_, __) => const _PlaceholderPage('ট্রেন্ডিং'),
      ),
      GoRoute(
        path: '/category/:name',
        name: 'category',
        builder: (context, state) {
          final name = Uri.decodeComponent(state.pathParameters['name']!);
          return CategoryListScreen(category: name);
        },
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
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    final auth = AuthService();
    if (!auth.isLoggedIn) {
      context.go(onboardingDone ? '/welcome' : '/onboarding');
      return;
    }
    final needs = await auth.needsProfileSetup();
    if (!mounted) return;
    context.go(needs ? '/profile-setup' : '/home');
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
