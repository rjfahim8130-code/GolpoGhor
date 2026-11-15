// lib/routing/route_names.dart
// discover রুট অক্ষুণ্ণ রেখে নতুন inbox রুট যুক্ত করা হয়েছে

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
  static const discover = '/discover'; // অক্ষুণ্ণ রাখা হলো
  static const inbox = '/inbox';       // নতুন ইনবক্স রুট
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
  static const videoSearch = '/video-search';

  // ---------- Author (NEW) ----------
  static const author = '/author';

  // ---------- History (NEW) ----------
  static const history = '/history';

  // ---------- Profile ----------
  static const profile = '/profile';
  static const user = '/user';
  static const editProfile = '/edit-profile';
  static const setPassword = '/set-password';
  static const myWorks = '/my-works';
  static const saved = '/saved';
  static const follows = '/follows';
  static const insights = '/insights';

  // ---------- Settings sub (NEW) ----------
  static const notificationSettings = '/settings/notifications';
  static const blockedUsers = '/settings/blocked';
  static const deleteAccount = '/settings/delete-account';

  // ---------- Offline ----------
  static const offline = '/offline';
  static const offlineReader = '/offline-reader';

  // ---------- Settings ----------
  static const settings = '/settings';

  // ---------- Admin ----------
  static const admin = '/admin';
  static const adminReports = '/admin/reports';
  static const adminReportDetail = '/admin/report-detail';
  static const adminUsers = '/admin/users';

  // ---------- Legal ----------
  static const legal = '/legal';
}
