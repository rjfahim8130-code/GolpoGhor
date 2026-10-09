import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/auth_service.dart';
import '../core/utils/network_check.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/home/presentation/screens/category_list_screen.dart';
import '../features/home/presentation/screens/discover_screen.dart';
import '../features/home/presentation/screens/home_feed_screen.dart';
import '../features/home/presentation/screens/popular_screen.dart';
import '../features/home/presentation/screens/trending_screen.dart';
import '../features/legal/presentation/screens/legal_screen.dart';
import '../features/novel/presentation/screens/add_episode_screen.dart';
import '../features/novel/presentation/screens/create_novel_screen.dart';
import '../features/novel/presentation/screens/episode_reader_screen.dart';
import '../features/novel/presentation/screens/novel_details_screen.dart';
import '../features/offline/presentation/screens/offline_downloads_screen.dart';
import '../features/offline/presentation/screens/offline_story_reader_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/follow_list_screen.dart';
import '../features/profile/presentation/screens/my_works_screen.dart';
import '../features/profile/presentation/screens/saved_stories_screen.dart';
import '../features/profile/presentation/screens/set_password_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/user_profile_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/story/presentation/screens/create_story_screen.dart';
import '../features/story/presentation/screens/drafts_screen.dart';
import '../features/story/presentation/screens/edit_story_screen.dart';
import '../features/story/presentation/screens/story_reader_screen.dart';

// ভিডিও ফিচারের ইমপোর্টসমূহ
import '../features/video/presentation/screens/create_video_screen.dart';
import '../features/video/presentation/screens/video_feed_screen.dart';
import '../features/video/presentation/screens/video_player_screen.dart';

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

      // অফলাইন — লগইন ছাড়াও ঢোকা যাবে
      final isOfflineRoute =
          loc == '/offline' || loc.startsWith('/offline-story');

      if (!loggedIn &&
          !isAuthRoute &&
          !isOfflineRoute &&
          loc != '/profile-setup') {
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
        builder: (_, __) => const DiscoverScreen(),
      ),
      GoRoute(
        path: '/popular',
        name: 'popular',
        builder: (_, __) => const PopularScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (_, __) => const SearchScreen(),
      ),
      // ---------- Video Routes ----------
      GoRoute(
        path: '/videos',
        name: 'videos',
        builder: (_, __) => const VideoFeedScreen(),
      ),
      GoRoute(
        path: '/create-video',
        name: 'create-video',
        builder: (_, __) => const CreateVideoScreen(),
      ),
      GoRoute(
        path: '/video/:id',
        name: 'video',
        builder: (_, state) => VideoPlayerScreen(
          videoId: state.pathParameters['id']!,
        ),
      ),
      // ----------------------------------
      GoRoute(
        path: '/story/:id',
        name: 'story',
        builder: (_, state) =>
            StoryReaderScreen(storyId: state.pathParameters['id']!),
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
            EditStoryScreen(storyId: state.pathParameters['id']!),
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
            NovelDetailsScreen(novelId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/create-novel',
        name: 'create-novel',
        builder: (_, __) => const CreateNovelScreen(),
      ),
      GoRoute(
        path: '/episode/:id',
        name: 'episode',
        builder: (_, state) =>
            EpisodeReaderScreen(episodeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/add-episode/:novelId',
        name: 'add-episode',
        builder: (_, state) =>
            AddEpisodeScreen(novelId: state.pathParameters['novelId']!),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        name: 'user',
        builder: (_, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/follows/:userId/:mode',
        name: 'follows',
        builder: (_, state) {
          final userId = state.pathParameters['userId']!;
          final mode = state.pathParameters['mode'] ?? 'followers';
          return FollowListScreen(userId: userId, mode: mode);
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
        builder: (_, state) => OfflineStoryReaderScreen(
          storyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/trending',
        name: 'trending',
        builder: (_, __) => const TrendingScreen(),
      ),
      GoRoute(
        path: '/category',
        name: 'category',
        builder: (_, state) {
          final name = state.uri.queryParameters['name'] ?? 'অন্যান্য';
          return CategoryListScreen(category: name);
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/legal/:type',
        name: 'legal',
        builder: (_, state) =>
            LegalScreen(type: state.pathParameters['type'] ?? 'terms'),
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthService auth) {
    auth.authStateChanges.listen((_) => notifyListeners());
  }
}

/// স্প্ল্যাশ: অনলাইন → হোম/অথ; অফলাইন → অফলাইন ডাউনলোড (আটকাবে না)
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
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final auth = AuthService();

    final online = await NetworkCheck.isOnline();

    if (!online) {
      if (!mounted) return;
      context.go('/offline');
      return;
    }

    if (!auth.isLoggedIn) {
      if (!mounted) return;
      context.go(onboardingDone ? '/welcome' : '/onboarding');
      return;
    }

    final cachedSetup = prefs.getBool('profile_setup_done') ?? false;
    if (cachedSetup) {
      if (!mounted) return;
      context.go('/home');
      return;
    }

    bool needsSetup = false;
    try {
      needsSetup = await auth
          .needsProfileSetup()
          .timeout(const Duration(seconds: 4));
      await prefs.setBool('profile_setup_done', !needsSetup);
    } catch (_) {
      needsSetup = false;
    }

    if (!mounted) return;
    context.go(needsSetup ? '/profile-setup' : '/home');
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
            SizedBox(height: 16),
            Text(
              'লোড হচ্ছে…',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
