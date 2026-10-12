// lib/core/constants/category_catalog.dart
// লেখা ও ভিডিও আলাদা — অপশনাল মেইন গ্রুপ + সাব

class CategoryItem {
  final String key;
  final String groupKey;
  const CategoryItem(this.key, this.groupKey);
}

class CategoryCatalog {
  CategoryCatalog._();

  // ───────── লেখার মেইন গ্রুপ ─────────
  static const List<String> writingGroups = [
    'grp_literature',
    'grp_islamic',
    'grp_history',
    'grp_romance',
    'grp_thriller',
    'grp_society',
    'grp_kids',
    'grp_poetry',
    'grp_scifi',
    'grp_biography',
    'grp_patriot',
    'grp_travel',
    'grp_comedy',
    'grp_fantasy',
    'grp_other',
  ];

  // ───────── ভিডিও মেইন গ্রুপ ─────────
  static const List<String> videoGroups = [
    'vgrp_story',
    'vgrp_islamic',
    'vgrp_history',
    'vgrp_poetry',
    'vgrp_drama',
    'vgrp_kids',
    'vgrp_comedy',
    'vgrp_documentary',
    'vgrp_author',
    'vgrp_other',
  ];

  // ───────── লেখার সাব ─────────
  static const List<CategoryItem> writingSubs = [
    // সাহিত্য
    CategoryItem('lit_short', 'grp_literature'),
    CategoryItem('lit_flash', 'grp_literature'),
    CategoryItem('lit_serial', 'grp_literature'),
    CategoryItem('lit_novel', 'grp_literature'),
    CategoryItem('lit_serial_novel', 'grp_literature'),
    CategoryItem('lit_folklore', 'grp_literature'),
    CategoryItem('lit_fairy', 'grp_literature'),
    // ইসলাম
    CategoryItem('isl_story', 'grp_islamic'),
    CategoryItem('isl_prophet', 'grp_islamic'),
    CategoryItem('isl_sahaba', 'grp_islamic'),
    CategoryItem('isl_history', 'grp_islamic'),
    CategoryItem('isl_moral', 'grp_islamic'),
    CategoryItem('isl_kids', 'grp_islamic'),
    // ইতিহাস
    CategoryItem('his_bd', 'grp_history'),
    CategoryItem('his_world', 'grp_history'),
    CategoryItem('his_liberation', 'grp_history'),
    CategoryItem('his_biography', 'grp_history'),
    // প্রেম
    CategoryItem('rom_romantic', 'grp_romance'),
    CategoryItem('rom_first', 'grp_romance'),
    CategoryItem('rom_separation', 'grp_romance'),
    CategoryItem('rom_family', 'grp_romance'),
    // রহস্য / ভৌতিক
    CategoryItem('thr_mystery', 'grp_thriller'),
    CategoryItem('thr_detective', 'grp_thriller'),
    CategoryItem('thr_horror', 'grp_thriller'),
    CategoryItem('thr_thriller', 'grp_thriller'),
    CategoryItem('thr_adventure', 'grp_thriller'),
    // সমাজ
    CategoryItem('soc_social', 'grp_society'),
    CategoryItem('soc_family', 'grp_society'),
    CategoryItem('soc_rural', 'grp_society'),
    CategoryItem('soc_urban', 'grp_society'),
    CategoryItem('soc_inspire', 'grp_society'),
    // শিশু-কিশোর
    CategoryItem('kid_children', 'grp_kids'),
    CategoryItem('kid_teen', 'grp_kids'),
    CategoryItem('kid_animal', 'grp_kids'),
    CategoryItem('kid_edu', 'grp_kids'),
    // কবিতা
    CategoryItem('poe_love', 'grp_poetry'),
    CategoryItem('poe_patriotic', 'grp_poetry'),
    CategoryItem('poe_islamic', 'grp_poetry'),
    CategoryItem('poe_modern', 'grp_poetry'),
    // সাই-ফাই
    CategoryItem('sci_scifi', 'grp_scifi'),
    CategoryItem('sci_space', 'grp_scifi'),
    CategoryItem('sci_tech', 'grp_scifi'),
    // জীবনী
    CategoryItem('bio_famous', 'grp_biography'),
    CategoryItem('bio_islamic', 'grp_biography'),
    CategoryItem('bio_freedom', 'grp_biography'),
    // দেশ / মুক্তিযুদ্ধ
    CategoryItem('nat_liberation', 'grp_patriot'),
    CategoryItem('nat_language', 'grp_patriot'),
    CategoryItem('nat_culture', 'grp_patriot'),
    // ভ্রমণ
    CategoryItem('trv_travel', 'grp_travel'),
    CategoryItem('trv_nature', 'grp_travel'),
    // কমেডি
    CategoryItem('com_funny', 'grp_comedy'),
    CategoryItem('com_satire', 'grp_comedy'),
    // ফ্যান্টাসি
    CategoryItem('fan_magic', 'grp_fantasy'),
    CategoryItem('fan_myth', 'grp_fantasy'),
    // অন্যান্য
    CategoryItem('oth_misc', 'grp_other'),
  ];

  // ───────── ভিডিও সাব ─────────
  static const List<CategoryItem> videoSubs = [
    CategoryItem('vid_story_read', 'vgrp_story'),
    CategoryItem('vid_novel_read', 'vgrp_story'),
    CategoryItem('vid_storytelling', 'vgrp_story'),
    CategoryItem('vid_islamic_story', 'vgrp_islamic'),
    CategoryItem('vid_islamic_talk', 'vgrp_islamic'),
    CategoryItem('vid_history', 'vgrp_history'),
    CategoryItem('vid_edu', 'vgrp_history'),
    CategoryItem('vid_poetry', 'vgrp_poetry'),
    CategoryItem('vid_drama', 'vgrp_drama'),
    CategoryItem('vid_shortfilm', 'vgrp_drama'),
    CategoryItem('vid_kids', 'vgrp_kids'),
    CategoryItem('vid_comedy', 'vgrp_comedy'),
    CategoryItem('vid_doc', 'vgrp_documentary'),
    CategoryItem('vid_travel', 'vgrp_documentary'),
    CategoryItem('vid_nature', 'vgrp_documentary'),
    CategoryItem('vid_author', 'vgrp_author'),
    CategoryItem('vid_review', 'vgrp_author'),
    CategoryItem('vid_other', 'vgrp_other'),
  ];

  static List<CategoryItem> writingSubsOf(String groupKey) =>
      writingSubs.where((e) => e.groupKey == groupKey).toList();

  static List<CategoryItem> videoSubsOf(String groupKey) =>
      videoSubs.where((e) => e.groupKey == groupKey).toList();

  /// সাব key থেকে গ্রুপ
  static String? groupOfSub(String subKey, {required bool video}) {
    final list = video ? videoSubs : writingSubs;
    for (final e in list) {
      if (e.key == subKey) return e.groupKey;
    }
    return null;
  }

  /// পুরনো ৮টা / বাংলা → নতুন key (optional migration)
  static const Map<String, String> legacyMap = {
    'প্রেম': 'rom_romantic',
    'রহস্য': 'thr_mystery',
    'হরর': 'thr_horror',
    'সামাজিক': 'soc_social',
    'ইতিহাস': 'his_bd',
    'কমেডি': 'com_funny',
    'কিশোর': 'kid_teen',
    'অন্যান্য': 'oth_misc',
    'catRomance': 'rom_romantic',
    'catMystery': 'thr_mystery',
    'catHorror': 'thr_horror',
    'catSocial': 'soc_social',
    'catHistory': 'his_bd',
    'catComedy': 'com_funny',
    'catTeen': 'kid_teen',
    'catOther': 'oth_misc',
  };

  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    return legacyMap[t] ?? t;
  }
}
