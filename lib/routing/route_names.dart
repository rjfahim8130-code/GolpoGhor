// lib/routing/route_names.dart
// সংশোধিত: unused 'write' const বাদ

class RouteNames {
  RouteNames._();

  // ---------- Splash / Auth ----------
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const profileSetup = '/profile-setup';

  // ---------- Main ----------
  static const home = '/home';
  static const discover = '/discover';
  static const popular = '/popular';
  static const trending = '/trending';
  static const category = '/category';
  static const search = '/search';
  static const notifications = '/notifications';

  // ---------- Reader ----------
  static const story = '/story';
  static const novel = '/novel';
  static const episode = '/episode';

  // ---------- Write ----------
  static const writeStory = '/write/story';
  static const writeNovel = '/write/novel';
  static const addEpisode = '/write/episode';
  static const drafts = '/drafts';

  // ---------- Video ----------
  static const videos = '/videos';
  static const createVideo = '/create-video';

  // ---------- Profile ----------
  static const profile = '/profile';
  static const user = '/user';
  static const editProfile = '/edit-profile';
  static const setPassword = '/set-password';
  static const myWorks = '/my-works';
  static const saved = '/saved';
  static const follows = '/follows';
  static const insights = '/insights';

  // ---------- Offline ----------
  static const offline = '/offline';
  static const offlineReader = '/offline-reader';

  // ---------- Settings ----------
  static const settings = '/settings';

  // ---------- Admin ----------
  static const admin = '/admin';

  // ---------- Legal ----------
  static const legal = '/legal';
}
