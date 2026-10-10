// lib/core/localization/app_localizations.dart
// সংশোধিত: shouldReload true, সব key getter, bangla+english

import 'package:flutter/material.dart';

import 'app_bn.dart';
import 'app_en.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('bn'),
    Locale('en'),
  ];

  static const Map<String, Map<String, String>> _strings = {
    'bn': AppBn.strings,
    'en': AppEn.strings,
  };

  /// ভাষা অনুযায়ী string ফেরত দেয়
  String t(String key) {
    final lang = _strings[locale.languageCode];
    if (lang != null && lang.containsKey(key)) return lang[key]!;
    // fallback to English
    if (AppEn.strings.containsKey(key)) return AppEn.strings[key]!;
    // fallback to Bangla
    if (AppBn.strings.containsKey(key)) return AppBn.strings[key]!;
    return key;
  }

  // ---- অ্যাপের নাম (সবসময় বাংলা) ----
  String get appName => 'গল্পঘর';

  // ---- Navigation ----
  String get home => t('home');
  String get discover => t('discover');
  String get popular => t('popular');
  String get trending => t('trending');
  String get search => t('search');
  String get videos => t('videos');
  String get notifications => t('notifications');
  String get profile => t('profile');
  String get settings => t('settings');

  // ---- Auth ----
  String get login => t('login');
  String get register => t('register');
  String get email => t('email');
  String get password => t('password');
  String get forgotPassword => t('forgotPassword');
  String get logout => t('logout');
  String get createAccount => t('createAccount');
  String get dontHaveAccount => t('dontHaveAccount');
  String get alreadyHaveAccount => t('alreadyHaveAccount');
  String get fullName => t('fullName');
  String get nickname => t('nickname');
  String get bio => t('bio');

  // ---- Common ----
  String get cancel => t('cancel');
  String get ok => t('ok');
  String get yes => t('yes');
  String get no => t('no');
  String get save => t('save');
  String get delete => t('delete');
  String get edit => t('edit');
  String get share => t('share');
  String get report => t('report');
  String get retry => t('retry');
  String get loading => t('loading');
  String get noData => t('noData');
  String get copy => t('copy');
  String get copied => t('copied');
  String get seeMore => t('seeMore');
  String get seeLess => t('seeLess');
  String get viewAll => t('viewAll');
  String get clearAll => t('clearAll');
  String get confirm => t('confirm');
  String get close => t('close');

  // ---- Content ----
  String get story => t('story');
  String get novel => t('novel');
  String get video => t('video');
  String get episode => t('episode');
  String get chapter => t('chapter');
  String get read => t('read');
  String get more => t('more');
  String get less => t('less');
  String get title => t('title');
  String get description => t('description');
  String get category => t('category');
  String get tags => t('tags');
  String get publish => t('publish');
  String get draft => t('draft');
  String get drafts => t('drafts');
  String get newStory => t('newStory');
  String get newNovel => t('newNovel');
  String get newVideo => t('newVideo');
  String get addEpisode => t('addEpisode');
  String get readNow => t('readNow');

  // ---- Social ----
  String get follow => t('follow');
  String get unfollow => t('unfollow');
  String get followers => t('followers');
  String get following => t('following');
  String get comment => t('comment');
  String get comments => t('comments');
  String get reply => t('reply');
  String get like => t('like');
  String get likes => t('likes');
  String get reactions => t('reactions');
  String get writeComment => t('writeComment');
  String get noComments => t('noComments');
  String get reaction => t('reaction');

  // ---- Library ----
  String get download => t('download');
  String get downloaded => t('downloaded');
  String get bookmark => t('bookmark');
  String get saved => t('saved');
  String get offline => t('offline');
  String get fontSize => t('fontSize');
  String get myWorks => t('myWorks');
  String get insights => t('insights');
  String get nextEpisode => t('nextEpisode');
  String get prevEpisode => t('prevEpisode');

  // ---- Settings ----
  String get theme => t('theme');
  String get language => t('language');
  String get bangla => t('bangla');
  String get english => t('english');
  String get system => t('system');
  String get dark => t('dark');
  String get light => t('light');
  String get legal => t('legal');
  String get terms => t('terms');
  String get privacy => t('privacy');
  String get about => t('about');
  String get version => t('version');
  String get supportEmail => t('supportEmail');
  String get deleteAccount => t('deleteAccount');
  String get deleteAccountConfirm => t('deleteAccountConfirm');
  String get accountDeletionScheduled => t('accountDeletionScheduled');
  String get logoutConfirm => t('logoutConfirm');

  // ---- Admin ----
  String get admin => t('admin');
  String get adminDashboard => t('adminDashboard');
  String get videoFeature => t('videoFeature');
  String get openReports => t('openReports');
  String get statistics => t('statistics');
  String get users => t('users');
  String get thisMonthNew => t('thisMonthNew');
  String get lastMonthNew => t('lastMonthNew');
  String get totalUsers => t('totalUsers');

  // ---- Errors ----
  String get somethingWentWrong => t('somethingWentWrong');
  String get noInternet => t('noInternet');
  String get tryAgain => t('tryAgain');
  String get loginFailed => t('loginFailed');
  String get registerFailed => t('registerFailed');
  String get saveFailed => t('saveFailed');
  String get uploadFailed => t('uploadFailed');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['bn', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  // ✅ গুরুত্বপূর্ণ: locale change হলে reload হবে
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

/// BuildContext shortcut
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
