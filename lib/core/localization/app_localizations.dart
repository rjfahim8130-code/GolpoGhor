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

  String t(String key) {
    final lang = _strings[locale.languageCode] ?? AppBn.strings;
    return lang[key] ?? AppBn.strings[key] ?? key;
  }

  // ---- Shortcut getters (সহজ ব্যবহারের জন্য) ----
  String get appName => t('appName');
  String get login => t('login');
  String get register => t('register');
  String get email => t('email');
  String get password => t('password');
  String get forgotPassword => t('forgotPassword');
  String get logout => t('logout');
  String get cancel => t('cancel');
  String get ok => t('ok');
  String get yes => t('yes');
  String get no => t('no');
  String get save => t('save');
  String get delete => t('delete');
  String get edit => t('edit');
  String get share => t('share');
  String get report => t('report');
  String get read => t('read');
  String get more => t('more');
  String get less => t('less');
  String get follow => t('follow');
  String get unfollow => t('unfollow');
  String get followers => t('followers');
  String get following => t('following');
  String get home => t('home');
  String get discover => t('discover');
  String get popular => t('popular');
  String get trending => t('trending');
  String get search => t('search');
  String get videos => t('videos');
  String get notifications => t('notifications');
  String get profile => t('profile');
  String get settings => t('settings');
  String get story => t('story');
  String get novel => t('novel');
  String get video => t('video');
  String get episode => t('episode');
  String get comment => t('comment');
  String get reply => t('reply');
  String get like => t('like');
  String get download => t('download');
  String get downloaded => t('downloaded');
  String get bookmark => t('bookmark');
  String get fontSize => t('fontSize');
  String get theme => t('theme');
  String get language => t('language');
  String get bangla => t('bangla');
  String get english => t('english');
  String get dark => t('dark');
  String get light => t('light');
  String get system => t('system');
  String get loading => t('loading');
  String get noData => t('noData');
  String get retry => t('retry');
  String get offline => t('offline');
  String get online => t('online');
  String get noInternet => t('noInternet');
  String get myWorks => t('myWorks');
  String get insights => t('insights');
  String get saved => t('saved');
  String get drafts => t('drafts');
  String get admin => t('admin');
  String get legal => t('legal');
  String get terms => t('terms');
  String get privacy => t('privacy');
  String get write => t('write');
  String get newStory => t('newStory');
  String get newNovel => t('newNovel');
  String get newVideo => t('newVideo');
  String get publish => t('publish');
  String get draft => t('draft');
  String get category => t('category');
  String get title => t('title');
  String get description => t('description');
  String get bio => t('bio');
  String get name => t('name');
  String get username => t('username');
  String get copy => t('copy');
  String get copied => t('copied');
  String get clearAll => t('clearAll');
  String get seeMore => t('seeMore');
  String get seeLess => t('seeLess');
  String get viewAll => t('viewAll');
  String get nextEpisode => t('nextEpisode');
  String get prevEpisode => t('prevEpisode');
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

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// BuildContext shortcut extension
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
