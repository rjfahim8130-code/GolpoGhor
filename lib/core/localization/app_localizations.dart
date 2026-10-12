// lib/core/localization/app_localizations.dart (Part 1)
// সম্পূর্ণ — getters (নতুন ক্যাটাগরি ও সার্চ গেটার সহ) + appName সবসময় বাংলা

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
    final lang = _strings[locale.languageCode];
    if (lang != null && lang.containsKey(key)) return lang[key]!;
    if (AppEn.strings.containsKey(key)) return AppEn.strings[key]!;
    if (AppBn.strings.containsKey(key)) return AppBn.strings[key]!;
    return key;
  }

  /// Brand — Home AppBar সহ সবসময় বাংলা
  String get appName => 'গল্পঘর';

  String get appTagline => t('appTagline');
  String get welcomeFooter => t('welcomeFooter');

  String get home => t('home');
  String get discover => t('discover');
  String get popular => t('popular');
  String get trending => t('trending');
  String get search => t('search');
  String get videos => t('videos');
  String get notifications => t('notifications');
  String get profile => t('profile');
  String get settings => t('settings');

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
  String get createNewAccount => t('createNewAccount');
  String get registerConsent => t('registerConsent');
  String get accountCreatedLogin => t('accountCreatedLogin');
  String get passwordAgain => t('passwordAgain');
  String get enterPasswordAgain => t('enterPasswordAgain');
  String get passwordsDoNotMatch => t('passwordsDoNotMatch');
  String get minSixChars => t('minSixChars');
  String get readOfflineStories => t('readOfflineStories');
  String get setupProfileHint => t('setupProfileHint');
  String get nicknameHelper => t('nicknameHelper');
  String get saveAndContinue => t('saveAndContinue');
  String get passwordReset => t('passwordReset');
  String get otpEmailHint => t('otpEmailHint');
  String get sendOtp => t('sendOtp');
  String get resendOtp => t('resendOtp');
  String get otpSent => t('otpSent');
  String get otpSentTo => t('otpSentTo');
  String get enterValidOtp => t('enterValidOtp');
  String get enterValidEmail => t('enterValidEmail');
  String get newPassword => t('newPassword');
  String get setPasswordAction => t('setPasswordAction');
  String get passwordChanged => t('passwordChanged');
  String get passwordMinSix => t('passwordMinSix');
  String get passwordMismatch => t('passwordMismatch');

  String get onboardTitle1 => t('onboardTitle1');
  String get onboardBody1 => t('onboardBody1');
  String get onboardTitle2 => t('onboardTitle2');
  String get onboardBody2 => t('onboardBody2');
  String get onboardTitle3 => t('onboardTitle3');
  String get onboardBody3 => t('onboardBody3');
  String get onboardTitle4 => t('onboardTitle4');
  String get onboardBody4 => t('onboardBody4');
  String get skip => t('skip');
  String get next => t('next');
  String get getStarted => t('getStarted');

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
  String get me => t('me');
  String get user => t('user');
  String get author => t('author');
  String get untitled => t('untitled');
  String get problem => t('problem');
  String get create => t('create');
  String get watch => t('watch');
  String get image => t('image');
  String get views => t('views');
  String get viewsCount => t('viewsCount');
  String get content => t('content');
  String get recent => t('recent');
  String get optional => t('optional');
  String get again => t('again');
  String get zero => t('zero');

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
  String get published => t('published');
  String get episodeN => t('episodeN');
  String get episodesDot => t('episodesDot');

  String get catRomance => t('catRomance');
  String get catMystery => t('catMystery');
  String get catHorror => t('catHorror');
  String get catSocial => t('catSocial');
  String get catHistory => t('catHistory');
  String get catComedy => t('catComedy');
  String get catTeen => t('catTeen');
  String get catOther => t('catOther');

  List<String> get categoryList => [
        catRomance,
        catMystery,
        catHorror,
        catSocial,
        catHistory,
        catComedy,
        catTeen,
        catOther,
      ];

  // ---- Category groups (writing) ----
  String get grpLiterature => t('grp_literature');
  String get grpIslamic => t('grp_islamic');
  String get grpHistory => t('grp_history');
  String get grpRomance => t('grp_romance');
  String get grpThriller => t('grp_thriller');
  String get grpSociety => t('grp_society');
  String get grpKids => t('grp_kids');
  String get grpPoetry => t('grp_poetry');
  String get grpScifi => t('grp_scifi');
  String get grpBiography => t('grp_biography');
  String get grpPatriot => t('grp_patriot');
  String get grpTravel => t('grp_travel');
  String get grpComedy => t('grp_comedy');
  String get grpFantasy => t('grp_fantasy');
  String get grpOther => t('grp_other');

  // ---- Writing subs ----
  String get litShort => t('lit_short');
  String get litFlash => t('lit_flash');
  String get litSerial => t('lit_serial');
  String get litNovel => t('lit_novel');
  String get litSerialNovel => t('lit_serial_novel');
  String get litFolklore => t('lit_folklore');
  String get litFairy => t('lit_fairy');
  String get islStory => t('isl_story');
  String get islProphet => t('isl_prophet');
  String get islSahaba => t('isl_sahaba');
  String get islHistory => t('isl_history');
  String get islMoral => t('isl_moral');
  String get islKids => t('isl_kids');
  String get hisBd => t('his_bd');
  String get hisWorld => t('his_world');
  String get hisLiberation => t('his_liberation');
  String get hisBiography => t('his_biography');
  String get romRomantic => t('rom_romantic');
  String get romFirst => t('rom_first');
  String get romSeparation => t('rom_separation');
  String get romFamily => t('rom_family');
  String get thrMystery => t('thr_mystery');
  String get thrDetective => t('thr_detective');
  String get thrHorror => t('thr_horror');
  String get thrThriller => t('thr_thriller');
  String get thrAdventure => t('thr_adventure');
  String get socSocial => t('soc_social');
  String get socFamily => t('soc_family');
  String get socRural => t('soc_rural');
  String get socUrban => t('soc_urban');
  String get socInspire => t('soc_inspire');
  String get kidChildren => t('kid_children');
  String get kidTeen => t('kid_teen');
  String get kidAnimal => t('kid_animal');
  String get kidEdu => t('kid_edu');
  String get poeLove => t('poe_love');
  String get poePatriotic => t('poe_patriotic');
  String get poeIslamic => t('poe_islamic');
  String get poeModern => t('poe_modern');
  String get sciScifi => t('sci_scifi');
  String get sciSpace => t('sci_space');
  String get sciTech => t('sci_tech');
  String get bioFamous => t('bio_famous');
  String get bioIslamic => t('bio_islamic');
  String get bioFreedom => t('bio_freedom');
  String get natLiberation => t('nat_liberation');
  String get natLanguage => t('nat_language');
  String get natCulture => t('nat_culture');
  String get trvTravel => t('trv_travel');
  String get trvNature => t('trv_nature');
  String get comFunny => t('com_funny');
  String get comSatire => t('com_satire');
  String get fanMagic => t('fan_magic');
  String get fanMyth => t('fan_myth');
  String get othMisc => t('oth_misc');

  // ---- Video groups & subs ----
  String get vgrpStory => t('vgrp_story');
  String get vgrpIslamic => t('vgrp_islamic');
  String get vgrpHistory => t('vgrp_history');
  String get vgrpPoetry => t('vgrp_poetry');
  String get vgrpDrama => t('vgrp_drama');
  String get vgrpKids => t('vgrp_kids');
  String get vgrpComedy => t('vgrp_comedy');
  String get vgrpDocumentary => t('vgrp_documentary');
  String get vgrpAuthor => t('vgrp_author');
  String get vgrpOther => t('vgrp_other');

  String get vidStoryRead => t('vid_story_read');
  String get vidNovelRead => t('vid_novel_read');
  String get vidStorytelling => t('vid_storytelling');
  String get vidIslamicStory => t('vid_islamic_story');
  String get vidIslamicTalk => t('vid_islamic_talk');
  String get vidHistory => t('vid_history');
  String get vidEdu => t('vid_edu');
  String get vidPoetry => t('vid_poetry');
  String get vidDrama => t('vid_drama');
  String get vidShortfilm => t('vid_shortfilm');
  String get vidKids => t('vid_kids');
  String get vidComedy => t('vid_comedy');
  String get vidDoc => t('vid_doc');
  String get vidTravel => t('vid_travel');
  String get vidNature => t('vid_nature');
  String get vidAuthor => t('vid_author');
  String get vidReview => t('vid_review');
  String get vidOther => t('vid_other');
  // lib/core/localization/app_localizations.dart (Part 2)

  String get loadFailed => t('loadFailed');
  String get notFound => t('notFound');
  String get noStoriesYet => t('noStoriesYet');
  String get noNovelsYet => t('noNovelsYet');
  String get noVideosYet => t('noVideosYet');
  String get noEpisodesYet => t('noEpisodesYet');
  String get noEpisodes => t('noEpisodes');
  String get noDrafts => t('noDrafts');
  String get noPopularYet => t('noPopularYet');
  String get noTrendingYet => t('noTrendingYet');
  String get noStoriesInCategory => t('noStoriesInCategory');
  String get noSearchResults => t('noSearchResults');
  String get noContent => t('noContent');
  String get noDownloads => t('noDownloads');
  String get noSavedStories => t('noSavedStories');
  String get noSavedNovels => t('noSavedNovels');
  String get noFollowers => t('noFollowers');
  String get notFollowingAnyone => t('notFollowingAnyone');
  String get noNotifications => t('noNotifications');
  String get noNotificationsHint => t('noNotificationsHint');
  String get noDownloadsHint => t('noDownloadsHint');
  String get uploadFirstVideo => t('uploadFirstVideo');
  String get profileNotFound => t('profileNotFound');
  String get novelNotFound => t('novelNotFound');
  String get videoNotFound => t('videoNotFound');
  String get offlineFileNotFound => t('offlineFileNotFound');

  String get searchHint => t('searchHint');
  String get searchCodeHint => t('searchCodeHint');
  String get codeMatched => t('codeMatched');
  String get authors => t('authors');
  String get searchAnythingTitle => t('searchAnythingTitle');
  String get searchAnythingSubtitle => t('searchAnythingSubtitle');
  String get mostReactions => t('mostReactions');
  String get mostRead => t('mostRead');
  String get shortVideoFeed => t('shortVideoFeed');
  String get popularSearches => t('popularSearches');
  String get optionalCategory => t('optionalCategory');
  String get selectGroup => t('selectGroup');
  String get selectSubcategory => t('selectSubcategory');
  String get noCategory => t('noCategory');
  String get clearCategory => t('clearCategory');

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
  String get mentionHint => t('mentionHint');
  String get reactionLike => t('reactionLike');
  String get reactionLove => t('reactionLove');
  String get reactionWow => t('reactionWow');
  String get reactionSad => t('reactionSad');
  String get reactionFire => t('reactionFire');
  String get followUpdated => t('followUpdated');

  String get reportReasonCopyright => t('reportReasonCopyright');
  String get reportReasonObscene => t('reportReasonObscene');
  String get reportReasonSpam => t('reportReasonSpam');
  String get reportReasonHarassment => t('reportReasonHarassment');
  String get reportReasonOther => t('reportReasonOther');
  String get reportEnterReason => t('reportEnterReason');
  String get reportSent => t('reportSent');
  String get pickReasonHint => t('pickReasonHint');
  String get detailedReasonHint => t('detailedReasonHint');
  String get sendReport => t('sendReport');
  String get reportStory => t('reportStory');
  String get reportEpisode => t('reportEpisode');
  String get reportNovel => t('reportNovel');
  String get reportVideo => t('reportVideo');

  String get deleteStoryConfirm => t('deleteStoryConfirm');
  String get deleteNovelConfirm => t('deleteNovelConfirm');
  String get deleteNovelConfirmBody => t('deleteNovelConfirmBody');
  String get deleteVideoConfirm => t('deleteVideoConfirm');
  String get cannotUndo => t('cannotUndo');
  String get cannotUndoLong => t('cannotUndoLong');

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
  String get bookmarkAdded => t('bookmarkAdded');
  String get bookmarkRemoved => t('bookmarkRemoved');
  String get downloadRemoved => t('downloadRemoved');
  String get downloadedOffline => t('downloadedOffline');
  String get downloadAllEpisodes => t('downloadAllEpisodes');
  String get episodesSavedOffline => t('episodesSavedOffline');
  String get goOnline => t('goOnline');
  String get stillOffline => t('stillOffline');
  String get noInternet => t('noInternet');
  String get offlineBanner => t('offlineBanner');
  String get removeFromOffline => t('removeFromOffline');

  String get enterTitle => t('enterTitle');
  String get addSomeText => t('addSomeText');
  String get editStory => t('editStory');
  String get editNovel => t('editNovel');
  String get coverImageOptional => t('coverImageOptional');
  String get tagsHint => t('tagsHint');
  String get titleOptional => t('titleOptional');
  String get addedParts => t('addedParts');
  String get addPart => t('addPart');
  String get writeTips => t('writeTips');
  String get novelNextEpisodeHint => t('novelNextEpisodeHint');
  String get blockHeading => t('blockHeading');
  String get blockBody => t('blockBody');
  String get blockEmphasis => t('blockEmphasis');
  String get blockQuote => t('blockQuote');
  String get hintHeading => t('hintHeading');
  String get hintEmphasis => t('hintEmphasis');
  String get hintQuote => t('hintQuote');
  String get hintBody => t('hintBody');
  String get hintEpisodeBody => t('hintEpisodeBody');
  String get hintHeadingShort => t('hintHeadingShort');
  String get hintEmphasisShort => t('hintEmphasisShort');
  String get hintQuoteShort => t('hintQuoteShort');
  String get enterEpisodeTitle => t('enterEpisodeTitle');
  String get episodeTitle => t('episodeTitle');
  String get episodeAdded => t('episodeAdded');
  String get updatedOn => t('updatedOn');
  String get episodeLabel => t('episodeLabel');
  String get series => t('series');
  String get seriesName => t('seriesName');
  String get partNumber => t('partNumber');
  String get seriesMode => t('seriesMode');
  String get seriesModeDesc => t('seriesModeDesc');

  String get videoFeatureDisabled => t('videoFeatureDisabled');
  String get videoTooLong => t('videoTooLong');
  String get pickVideoFirst => t('pickVideoFirst');
  String get pickFromGallery => t('pickFromGallery');
  String get compressingVideo => t('compressingVideo');
  String get uploadingPleaseWait => t('uploadingPleaseWait');
  String get durationOfMax => t('durationOfMax');
  String get autoLoop => t('autoLoop');
  String get soundOn => t('soundOn');
  String get soundOff => t('soundOff');
  String get watchNextPart => t('watchNextPart');
  String get advertisement => t('advertisement');

  String get editProfile => t('editProfile');
  String get myCode => t('myCode');
  String get youAreAdmin => t('youAreAdmin');
  String get avatarChangeHint => t('avatarChangeHint');
  String get systemLanguageHint => t('systemLanguageHint');
  String get deleteAction => t('deleteAction');
  String get passwordAgainLabel => t('passwordAgainLabel');
  String get doesNotMatch => t('doesNotMatch');
  String get setPasswordHelp => t('setPasswordHelp');
  String get setPasswordHelpWithEmail => t('setPasswordHelpWithEmail');
  String get thisWeek => t('thisWeek');
  String get thisMonth => t('thisMonth');
  String get insightsWritingHeader => t('insightsWritingHeader');
  String get insightsCompareHint => t('insightsCompareHint');
  String get seen => t('seen');
  String get saves => t('saves');
  String get viewDelta => t('viewDelta');

  String get notifReacted => t('notifReacted');
  String get notifCommented => t('notifCommented');
  String get notifReplied => t('notifReplied');
  String get notifMentioned => t('notifMentioned');
  String get notifFollowed => t('notifFollowed');
  String get notification => t('notification');
  String get mentionNotificationBody => t('mentionNotificationBody');

  String get shareReadOnApp => t('shareReadOnApp');
  String get shareFollowOnApp => t('shareFollowOnApp');
  String get shareCodeLabel => t('shareCodeLabel');

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
  String get setPassword => t('setPassword');

  String get admin => t('admin');
  String get adminDashboard => t('adminDashboard');
  String get videoFeature => t('videoFeature');
  String get openReports => t('openReports');
  String get statistics => t('statistics');
  String get users => t('users');
  String get thisMonthNew => t('thisMonthNew');
  String get lastMonthNew => t('lastMonthNew');
  String get totalUsers => t('totalUsers');
  String get open => t('open');
  String get reviewed => t('reviewed');
  String get unpublish => t('unpublish');
  String get moderation => t('moderation');
  String get videoFeatureOn => t('videoFeatureOn');
  String get videoFeatureOff => t('videoFeatureOff');
  String get noOpenReports => t('noOpenReports');
  String get typeLabel => t('typeLabel');
  String get reasonLabel => t('reasonLabel');
  String get videoFeatureDescOn => t('videoFeatureDescOn');
  String get videoFeatureDescOff => t('videoFeatureDescOff');
  String get accessDenied => t('accessDenied');
  String get adminOnlyScreen => t('adminOnlyScreen');
  String get moderationHint => t('moderationHint');
  String get monthlyUsers => t('monthlyUsers');
  String get featureControl => t('featureControl');
  String get mauLimitNote => t('mauLimitNote');

  String get valEnterEmail => t('valEnterEmail');
  String get valValidEmail => t('valValidEmail');
  String get valEnterPassword => t('valEnterPassword');
  String get valMinSix => t('valMinSix');
  String get valEnterName => t('valEnterName');
  String get valMinTwo => t('valMinTwo');
  String get valMaxThirty => t('valMaxThirty');
  String get valEnterTitle => t('valEnterTitle');

  String get timeJustNow => t('timeJustNow');
  String get timeSecondsAgo => t('timeSecondsAgo');
  String get timeMinutesAgo => t('timeMinutesAgo');
  String get timeHoursAgo => t('timeHoursAgo');
  String get timeDaysAgo => t('timeDaysAgo');
  String get timeWeeksAgo => t('timeWeeksAgo');
  String get timeMonthsAgo => t('timeMonthsAgo');
  String get timeYearsAgo => t('timeYearsAgo');
  String get compactThousand => t('compactThousand');
  String get compactLakh => t('compactLakh');
  String get compactCrore => t('compactCrore');

  String get somethingWentWrong => t('somethingWentWrong');
  String get tryAgain => t('tryAgain');
  String get loginFailed => t('loginFailed');
  String get registerFailed => t('registerFailed');
  String get saveFailed => t('saveFailed');
  String get uploadFailed => t('uploadFailed');
  String get notLoggedIn => t('notLoggedIn');
  String get invalidOtp => t('invalidOtp');
  String get commentEmpty => t('commentEmpty');
  String get commentTooLong => t('commentTooLong');
  String get cannotFollowSelf => t('cannotFollowSelf');
  String get noEpisodePermission => t('noEpisodePermission');
  String get reasonMinFive => t('reasonMinFive');
  String get reasonTooLong => t('reasonTooLong');
  String get r2ConfigMissing => t('r2ConfigMissing');
  String get r2UploadFailed => t('r2UploadFailed');
  String get appFailedToStart => t('appFailedToStart');
  String get bootErrorHelp => t('bootErrorHelp');
  String get needAtLeastOneId => t('needAtLeastOneId');
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
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
