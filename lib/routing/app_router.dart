// lib/routing/app_router.dart
// সংশোধিত: admin guard, set_password import, সব ঠিক

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/auth_service.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/home/presentation/screens/category_screen.dart';
import '../features/home/presentation/screens/discover_screen.dart';
import '../features/home/presentation/screens/home_feed_screen.dart';
import '../features/home/presentation/screens/popular_screen.dart';
import '../features/home/presentation/screens/trending_screen.dart';
import '../features/legal/presentation/screens/legal_screen.dart';
import '../features/notification/presentation/screens/notification_screen.dart';
import '../features/novel/presentation/screens/novel_details_screen.dart';
import '../features/offline/presentation/screens/offline_downloads_screen.dart';
import '../features/offline/presentation/screens/offline_reader_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/follow_list_screen.dart';
import '../features/profile/presentation/screens/insights_screen.dart';
import '../features/profile/presentation/screens/my_posts_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/saved_screen.dart';
import '../features/profile/presentation/screens/set_password_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/reader/presentation/screens/reader_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/video/presentation/screens/create_video_screen.dart';
import '../features/video/presentation/screens/edit_video_screen.dart';
import '../features/video/presentation/screens/video_feed_screen.dart';
import '../features/write/presentation/screens/add_episode_screen.dart';
import '../features/write/presentation/screens/draft_list_screen.dart';
import '../features/write/presentation/screens/write_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = AuthService();

  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: _AuthRefresh(auth),
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final loc = state.matchedLocation;

      final isAuthRoute = loc == RouteNames.welcome ||
          loc == RouteNames.login ||
          loc == RouteNames.register ||
          loc == RouteNames.forgotPassword ||
          loc == RouteNames.splash ||
          loc == RouteNames.onboarding ||
          loc == RouteNames.profileSetup;

      final isOfflineRoute = loc == RouteNames.offline ||
          loc.startsWith('${RouteNames.offlineReader}/');

      final isLegalRoute = loc.startsWith(RouteNames.legal);

      // লগইন ছাড়াও যাওয়া যাবে: auth routes, offline, legal
      if (!loggedIn &&
          !isAuthRoute &&
          !isOfflineRoute &&
          !isLegalRoute) {
        return RouteNames.welcome;
      }

      // ⚠️ Admin guard — লগইন থাকলেও admin check হবে
      if (loc.startsWith(RouteNames.admin)) {
        if (!loggedIn) return RouteNames.welcome;
        // Admin check screen-level-এ হবে (async) —
        // এখানে শুধু লগইন চেক করা হচ্ছে
      }

      return null;
    },
    routes: [
      // ---------- Splash & Onboarding ----------
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ---------- Auth ----------
      GoRoute(
        path: RouteNames.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),

      // ---------- Home ----------
      GoRoute(
        path: RouteNames.home,
        builder: (_, __) => const HomeFeedScreen(),
      ),
      GoRoute(
        path: RouteNames.discover,
        builder: (_, __) => const DiscoverScreen(),
      ),
      GoRoute(
        path: RouteNames.popular,
        builder: (_, __) => const PopularScreen(),
      ),
      GoRoute(
        path: RouteNames.trending,
        builder: (_, __) => const TrendingScreen(),
      ),
      GoRoute(
        path: RouteNames.category,
        builder: (_, state) {
          final name = state.uri.queryParameters['name'] ?? 'অন্যান্য';
          return CategoryScreen(category: name);
        },
      ),
      GoRoute(
        path: RouteNames.search,
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (_, __) => const NotificationScreen(),
      ),

      // ---------- Reader ----------
      GoRoute(
        path: '${RouteNames.story}/:id',
        builder: (_, state) => ReaderScreen(
          kind: ReaderKind.story,
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${RouteNames.episode}/:id',
        builder: (_, state) => ReaderScreen(
          kind: ReaderKind.episode,
          id: state.pathParameters['id']!,
        ),
      ),

      // ---------- Novel details ----------
      GoRoute(
        path: '${RouteNames.novel}/:id',
        builder: (_, state) => NovelDetailsScreen(
          novelId: state.pathParameters['id']!,
        ),
      ),

      // ---------- Write ----------
      GoRoute(
        path: RouteNames.writeStory,
        builder: (_, __) => const WriteScreen(kind: WriteKind.story),
      ),
      GoRoute(
        path: '${RouteNames.writeStory}/:id',
        builder: (_, state) => WriteScreen(
          kind: WriteKind.story,
          editId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.writeNovel,
        builder: (_, __) => const WriteScreen(kind: WriteKind.novel),
      ),
      GoRoute(
        path: '${RouteNames.writeNovel}/:id',
        builder: (_, state) => WriteScreen(
          kind: WriteKind.novel,
          editId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${RouteNames.addEpisode}/:novelId',
        builder: (_, state) => AddEpisodeScreen(
          novelId: state.pathParameters['novelId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.drafts,
        builder: (_, __) => const DraftListScreen(),
      ),

      // ---------- Video ----------
      GoRoute(
        path: RouteNames.videos,
        builder: (_, state) {
          final focus = state.uri.queryParameters['focus'];
          return VideoFeedScreen(focusVideoId: focus);
        },
      ),
      GoRoute(
        path: RouteNames.createVideo,
        builder: (_, __) => const CreateVideoScreen(),
      ),
      GoRoute(
        path: '${RouteNames.createVideo}/:id',
        builder: (_, state) => EditVideoScreen(
          videoId: state.pathParameters['id']!,
        ),
      ),

      // ---------- Profile ----------
      GoRoute(
        path: RouteNames.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '${RouteNames.user}/:id',
        builder: (_, state) => ProfileScreen(
          userId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.setPassword,
        builder: (_, __) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.myWorks,
        builder: (_, __) => const MyPostsScreen(),
      ),
      GoRoute(
        path: RouteNames.saved,
        builder: (_, __) => const SavedScreen(),
      ),
      GoRoute(
        path: '${RouteNames.follows}/:userId/:mode',
        builder: (_, state) {
          final uid = state.pathParameters['userId']!;
          final mode = state.pathParameters['mode'] ?? 'followers';
          return FollowListScreen(userId: uid, mode: mode);
        },
      ),
      GoRoute(
        path: RouteNames.insights,
        builder: (_, __) => const InsightsScreen(),
      ),

      // ---------- Offline ----------
      GoRoute(
        path: RouteNames.offline,
        builder: (_, __) => const OfflineDownloadsScreen(),
      ),
      GoRoute(
        path: '${RouteNames.offlineReader}/:id',
        builder: (_, state) => OfflineReaderScreen(
          itemId: state.pathParameters['id']!,
        ),
      ),

      // ---------- Settings ----------
      GoRoute(
        path: RouteNames.settings,
        builder: (_, __) => const SettingsScreen(),
      ),

      // ---------- Admin ----------
      GoRoute(
        path: RouteNames.admin,
        builder: (_, __) => const AdminDashboardScreen(),
      ),

      // ---------- Legal ----------
      GoRoute(
        path: '${RouteNames.legal}/:type',
        builder: (_, state) => LegalScreen(
          type: state.pathParameters['type'] ?? 'terms',
        ),
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(AuthService auth) {
    auth.authStateChanges.listen((_) => notifyListeners());
  }
}
