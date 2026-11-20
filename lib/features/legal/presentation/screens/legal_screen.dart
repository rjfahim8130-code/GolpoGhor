// lib/features/legal/presentation/screens/legal_screen.dart
// সম্পূর্ণ নতুন: বাংলা + ইংরেজি content, ভাষা অনুযায়ী স্বয়ংক্রিয়

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';

class LegalScreen extends StatelessWidget {
  final String type; // terms | privacy

  const LegalScreen({super.key, required this.type});

  bool get _isTerms => type == 'terms';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    final title = _isTerms ? l10n.terms : l10n.privacy;
    final body = isBn
        ? (_isTerms ? _termsBn : _privacyBn)
        : (_isTerms ? _termsEn : _privacyEn);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            body,
            style: const TextStyle(height: 1.6, fontSize: 14),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ============================================================
  // TERMS — বাংলা
  // ============================================================
  static const _termsBn = '''
ব্যবহারের শর্তাবলী
গল্পঘর (GolpoGhor)
সর্বশেষ আপডেট: ১০ অক্টোবর, ২০২৬

গল্পঘরে স্বাগতম। গল্পঘর ব্যবহার করার মাধ্যমে আপনি এই ব্যবহারের শর্তাবলী মেনে চলতে সম্মত হচ্ছেন। কোনো শর্তে সম্মত না হলে সংশ্লিষ্ট সেবা ব্যবহার করা থেকে বিরত থাকুন।

এই শর্তাবলীর উদ্দেশ্য হলো পাঠক, লেখক, দর্শক এবং প্ল্যাটফর্ম—সবার জন্য একটি নিরাপদ, সম্মানজনক ও সৃজনশীল পরিবেশ নিশ্চিত করা।

১. গল্পঘরের সেবা

গল্পঘর একটি বাংলা সাহিত্য ও ডিজিটাল কনটেন্ট প্ল্যাটফর্ম। এখানে প্রযোজ্য ফিচার ও অনুমতির ভিত্তিতে ব্যবহারকারীরা:

• গল্প, উপন্যাস ও ধারাবাহিক পর্ব পড়তে পারবেন।
• অনুমোদিত সুবিধার মাধ্যমে নিজস্ব লেখা প্রকাশ করতে পারবেন।
• ভিডিও ও অন্যান্য সমর্থিত মিডিয়া দেখতে বা প্রকাশ করতে পারবেন।
• লেখক ও অন্যান্য ব্যবহারকারীকে অনুসরণ করতে পারবেন।
• মন্তব্য, রিয়্যাকশন, বুকমার্ক এবং অন্যান্য ইন্টারঅ্যাকশন ব্যবহার করতে পারবেন।

সব ফিচার সব ব্যবহারকারীর জন্য একইভাবে উপলভ্য নাও হতে পারে।

২. অ্যাকাউন্ট ও ব্যবহারকারীর দায়িত্ব

গল্পঘর ব্যবহার করার সময় আপনি সম্মত হচ্ছেন যে:

• নিবন্ধনের সময় সঠিক ও প্রয়োজনীয় তথ্য প্রদান করবেন।
• নিজের লগইন তথ্য ও অ্যাকাউন্টের নিরাপত্তা রক্ষা করবেন।
• নিজের অ্যাকাউন্টে সংঘটিত কার্যকলাপ সম্পর্কে যথাযথ সতর্কতা অবলম্বন করবেন।
• অন্যের অ্যাকাউন্টে অননুমোদিত প্রবেশ বা পরিচয় জালিয়াতি করবেন না।
• স্প্যাম, প্রতারণা, হয়রানি কিংবা প্ল্যাটফর্মের স্বাভাবিক কার্যক্রমে বাধা সৃষ্টি করবেন না।

অ্যাকাউন্টের নিরাপত্তা বিঘ্নিত হলে যত দ্রুত সম্ভব আমাদের জানাতে হবে।

৩. কনটেন্টের মালিকানা ও কপিরাইট

আপনার সৃষ্টি, আপনার অধিকার।

আপনি গল্পঘরে যে মৌলিক গল্প, উপন্যাস, লেখা, ভিডিও, ছবি বা অন্যান্য কনটেন্ট তৈরি করেন, তার ওপর আপনার বিদ্যমান মালিকানা ও মেধাস্বত্ব বজায় থাকবে।

তবে কনটেন্ট প্রকাশ করার মাধ্যমে আপনি গল্পঘরকে প্ল্যাটফর্মে সেটি হোস্ট, সংরক্ষণ, প্রদর্শন, ফরম্যাট অনুযায়ী প্রস্তুত এবং আপনার নির্বাচিত ফিচার অনুযায়ী বিতরণ করার জন্য প্রয়োজনীয় সীমিত, অ-একচেটিয়া লাইসেন্স প্রদান করেন। এই লাইসেন্স কেবল সেবা পরিচালনা ও আপনার নির্বাচিত প্রকাশনা-সুবিধা প্রদানের উদ্দেশ্যে প্রযোজ্য।

এই শর্তের অর্থ আপনার কনটেন্টের মালিকানা গল্পঘরের কাছে হস্তান্তর করা নয়।

আপনি সম্মত হচ্ছেন যে:

• অন্যের লেখা, ভিডিও, ছবি বা সৃষ্টিকর্ম অনুমতি ছাড়া নিজের নামে প্রকাশ করবেন না।
• কপিরাইট, ট্রেডমার্ক বা অন্যের আইনগত অধিকার লঙ্ঘন করবেন না।
• প্রয়োজনীয় অনুমতি ছাড়া অন্যের কনটেন্ট বাণিজ্যিকভাবে ব্যবহার করবেন না।
• আপনার প্রকাশিত কনটেন্টের অধিকার ও প্রয়োজনীয় অনুমতি নিশ্চিত করার দায়িত্ব আপনার।

৪. কনটেন্ট প্রকাশ ও মডারেশন

গল্পঘর একটি নিরাপদ ও সম্মানজনক পরিবেশ বজায় রাখতে কাজ করবে। নিচের ধরনের কনটেন্ট নিষিদ্ধ বা সীমাবদ্ধ করা হতে পারে:

• বেআইনি, প্রতারণামূলক বা অন্যের অধিকার লঙ্ঘনকারী কনটেন্ট।
• ঘৃণাত্মক বক্তব্য, বিশ্বাসযোগ্য হুমকি বা লক্ষ্যভিত্তিক হয়রানি।
• অনুমতি ছাড়া প্রকাশিত ব্যক্তিগত বা গোপন তথ্য।
• ম্যালওয়্যার, ক্ষতিকর লিংক, স্প্যাম বা প্রতারণামূলক প্রচারণা।
• প্রযোজ্য আইন বা প্ল্যাটফর্মের নীতিমালা লঙ্ঘনকারী কনটেন্ট।
• প্রযোজ্য বয়সসীমা বা শিশু সুরক্ষাবিধি লঙ্ঘনকারী কনটেন্ট।

প্রয়োজনে কোনো কনটেন্ট সাময়িকভাবে সীমিত, সরানো বা পর্যালোচনার জন্য আটকে রাখা হতে পারে। গুরুতর বা পুনরাবৃত্ত লঙ্ঘনের ক্ষেত্রে অ্যাকাউন্টের ওপর বিধিনিষেধ আরোপ করা হতে পারে।

৫. ভিডিও প্রকাশের নিয়ম

ভিডিও প্রকাশের সুবিধা অনুমোদিত ব্যবহারকারী বা নির্ধারিত অ্যাকাউন্টের জন্য সীমিত থাকতে পারে।

ভিডিও আপলোড করার সময় আপনাকে নিশ্চিত করতে হবে যে:

• ভিডিওটি প্রকাশ করার প্রয়োজনীয় অধিকার বা অনুমতি আপনার রয়েছে।
• ভিডিওতে অন্যের গোপনীয়তা, নিরাপত্তা বা আইনগত অধিকার অযথা লঙ্ঘিত হচ্ছে না।
• ভিডিওর শিরোনাম, বিবরণ, ট্যাগ এবং অন্যান্য তথ্য যথাসম্ভব সঠিক।
• ভিডিওটি গল্পঘরের কনটেন্ট নীতিমালা ও প্রযোজ্য আইন অনুসরণ করে।

গল্পঘর প্রয়োজনীয় ভিডিও পর্যালোচনা, সীমাবদ্ধ বা অপসারণ করতে পারে।

৬. মন্তব্য, অনুসরণ ও সামাজিক আচরণ

গল্পঘরের সামাজিক ফিচার ব্যবহার করার সময় অন্য ব্যবহারকারীর প্রতি সম্মান বজায় রাখতে হবে।

কাউকে হুমকি দেওয়া, ব্যক্তিগতভাবে আক্রমণ করা, হয়রানি করা, বারবার অনাকাঙ্ক্ষিত বার্তা দেওয়া বা অন্যের স্বাভাবিক ব্যবহার ব্যাহত করা গ্রহণযোগ্য নয়।

অন্য ব্যবহারকারীর মতামত বা প্রকাশিত কনটেন্টের সঙ্গে দ্বিমত থাকতে পারে; তবে মতবিরোধের কারণে অপমান, হুমকি বা ক্ষতিকর আচরণ গ্রহণযোগ্য হবে না।

৭. ডাউনলোড ও অফলাইন ব্যবহার

ডাউনলোড ফিচার উপলভ্য থাকলে তা ব্যক্তিগত ও অনুমোদিত ব্যবহারের জন্য প্রদান করা হবে।

লেখক বা অধিকারধারীর অনুমতি এবং প্রযোজ্য আইন ছাড়া ডাউনলোড করা কনটেন্ট পুনর্বিতরণ, বাণিজ্যিকভাবে বিক্রি, নিজের নামে পুনঃপ্রকাশ বা অন্য প্ল্যাটফর্মে পুনরায় আপলোড করা যাবে না।

কোনো কনটেন্ট অফলাইনে উপলভ্য হওয়া মানেই সেটির কপিরাইট আপনার হয়ে যাওয়া নয়।

৮. রিপোর্ট, অভিযোগ ও কপিরাইট দাবি

কোনো কনটেন্ট নিয়ম লঙ্ঘন করছে, হয়রানিমূলক বা আপনার মেধাস্বত্বের অধিকার লঙ্ঘন করছে বলে মনে হলে অ্যাপের রিপোর্ট ফিচার অথবা নির্ধারিত সাপোর্ট ঠিকানার মাধ্যমে অভিযোগ জানাতে পারবেন।

অভিযোগ পর্যালোচনার জন্য প্রয়োজনীয় তথ্য চাওয়া হতে পারে। প্রযোজ্য আইন অনুযায়ী ব্যবস্থা নেওয়া হবে। যথাযথ ক্ষেত্রে সংশ্লিষ্ট কনটেন্ট সীমিত করা, সরানো বা সংশ্লিষ্ট ব্যবহারকারীর অ্যাকাউন্ট পর্যালোচনা করা হতে পারে।

৯. বিজ্ঞাপন, প্রিমিয়াম ফিচার ও পেমেন্ট

গল্পঘরে ভবিষ্যতে বিজ্ঞাপন, সাবস্ক্রিপশন, প্রিমিয়াম সুবিধা বা অর্থপ্রদানের মাধ্যমে কনটেন্ট ব্যবহারের ব্যবস্থা চালু হতে পারে।

এ ধরনের ফিচার চালু হলে মূল্য, বিলিংয়ের সময়কাল, নবায়ন, বাতিলকরণ, ফেরত এবং প্রযোজ্য অন্যান্য শর্ত সংশ্লিষ্ট ফিচারের মাধ্যমে জানানো হবে।

কোনো অর্থপ্রদানের সুবিধা চালু হওয়ার আগে সংশ্লিষ্ট শর্তাবলী ও প্রযোজ্য আইন অনুসরণ করা হবে।

১০. সেবার প্রাপ্যতা ও দায়ের সীমা

গল্পঘর সেবা নিরবচ্ছিন্ন ও ত্রুটিমুক্ত রাখার যুক্তিসংগত চেষ্টা করবে। তবে রক্ষণাবেক্ষণ, প্রযুক্তিগত সমস্যা, নেটওয়ার্ক বিভ্রাট বা তৃতীয় পক্ষের সেবার কারণে সাময়িক বিঘ্ন ঘটতে পারে।

প্ল্যাটফর্মে প্রকাশিত ব্যবহারকারীদের মতামত, গল্প বা ভিডিও সবসময় গল্পঘরের নিজস্ব মতামতকে প্রতিফলিত করে না।

প্রযোজ্য আইনে অনুমোদিত সীমার মধ্যে, সেবার ব্যবহার বা সাময়িক অপ্রাপ্যতার ফলে সৃষ্ট ক্ষতির দায় সীমিত হতে পারে। তবে যে দায় আইন অনুযায়ী বাদ দেওয়া বা সীমিত করা যায় না, এই শর্ত তার ওপর প্রভাব ফেলবে না।

১১. অ্যাকাউন্ট স্থগিত বা বন্ধ করা

এই শর্তাবলী, কনটেন্ট নীতিমালা বা প্রযোজ্য আইন লঙ্ঘিত হলে গল্পঘর যথাযথ ব্যবস্থা নিতে পারে। পরিস্থিতি অনুযায়ী সতর্কতা, নির্দিষ্ট ফিচার সীমিত করা, কনটেন্ট সরানো, অ্যাকাউন্ট সাময়িক স্থগিত বা বন্ধ করার ব্যবস্থা নেওয়া হতে পারে।

ব্যবহারকারীও প্রযোজ্য পদ্ধতি অনুসরণ করে নিজের অ্যাকাউন্ট বন্ধ করার অনুরোধ করতে পারবেন। অ্যাকাউন্ট বন্ধ করার পরও আইনগত বা নিরাপত্তার কারণে কিছু তথ্য সীমিত সময় সংরক্ষিত থাকতে পারে।

১২. শর্তাবলীর পরিবর্তন

নতুন ফিচার, প্রযুক্তিগত পরিবর্তন বা আইনগত প্রয়োজনের কারণে এই শর্তাবলী হালনাগাদ করা হতে পারে। গুরুত্বপূর্ণ পরিবর্তনের ক্ষেত্রে যুক্তিসংগতভাবে ব্যবহারকারীদের জানানো হবে।

সর্বশেষ সংস্করণ ও আপডেটের তারিখ এই পাতায় প্রকাশ করা হবে।

১৩. প্রযোজ্য আইন

গল্পঘরের সেবা ও এই শর্তাবলীর ক্ষেত্রে প্রযোজ্য আইন অনুসরণ করা হবে। কোনো বিরোধ দেখা দিলে প্রযোজ্য আইন অনুযায়ী তার সমাধান করা হবে।

১৪. যোগাযোগ

ব্যবহারের শর্ত, কপিরাইট, রিপোর্ট বা অন্যান্য অভিযোগের জন্য:

ইমেইল: support@golpoghor.app
অ্যাপ: গল্পঘর → সেটিংস → সহায়তা ও যোগাযোগ

গল্পঘরকে নিরাপদ, সৃজনশীল এবং সবার জন্য সম্মানজনক প্ল্যাটফর্ম হিসেবে গড়ে তুলতে আপনার সহযোগিতা কাম্য।
''';

  // ============================================================
  // PRIVACY — বাংলা
  // ============================================================
  static const _privacyBn = '''
গোপনীয়তা নীতি
গল্পঘর (GolpoGhor)
সর্বশেষ আপডেট: ১০ অক্টোবর, ২০২৬

গল্পঘরে আপনাকে স্বাগতম। গল্পঘর এমন একটি ডিজিটাল প্ল্যাটফর্ম, যেখানে পাঠক গল্প পড়েন, লেখক তাঁদের সৃষ্টিশীলতা প্রকাশ করেন এবং ব্যবহারকারীরা সাহিত্য ও ভিডিও কনটেন্টের মাধ্যমে নতুন অভিজ্ঞতা লাভ করেন।

আপনার ব্যক্তিগত তথ্যের গোপনীয়তা, নিরাপত্তা এবং আপনার সৃষ্টিশীল কাজের প্রতি সম্মান আমাদের কাছে গুরুত্বপূর্ণ। এই গোপনীয়তা নীতিতে ব্যাখ্যা করা হয়েছে, গল্পঘর কী ধরনের তথ্য সংগ্রহ করতে পারে, কেন তা ব্যবহার করে, কীভাবে সংরক্ষণ করে এবং আপনার কী কী অধিকার রয়েছে।

১. গল্পঘর সম্পর্কে

গল্পঘর একটি বাংলা গল্প, উপন্যাস, ধারাবাহিক সাহিত্য এবং অনুমোদিত ভিডিও কনটেন্ট প্রকাশ ও উপভোগের ডিজিটাল প্ল্যাটফর্ম। এই নীতি গল্পঘর অ্যাপ, সংশ্লিষ্ট অনলাইন সেবা এবং প্রযোজ্য ক্ষেত্রে এর অন্যান্য ডিজিটাল ফিচারের জন্য প্রযোজ্য।

২. আমরা কী ধরনের তথ্য সংগ্রহ করি

সেবা পরিচালনা, ব্যবহারকারীর অভিজ্ঞতা উন্নত করা এবং প্ল্যাটফর্মের নিরাপত্তা বজায় রাখার প্রয়োজনে আমরা নিম্নলিখিত তথ্য সংগ্রহ করতে পারি।

ক. আপনার দেওয়া তথ্য

• অ্যাকাউন্ট তৈরির সময় নাম, ইমেইল ঠিকানা, ডাক নাম ও প্রোফাইল ছবি।
• আপনার প্রোফাইলে যোগ করা পরিচিতি বা অন্যান্য ঐচ্ছিক তথ্য।
• আপনার লেখা গল্প, উপন্যাস, পর্ব, ভিডিও, ক্যাপশন, ট্যাগ এবং আপলোড করা মিডিয়া।
• আপনার করা মন্তব্য, রিয়্যাকশন, বুকমার্ক, ফলো এবং অন্যান্য কার্যক্রম।

খ. স্বয়ংক্রিয়ভাবে সংগৃহীত তথ্য

• লগইন সেশন, অ্যাপের পছন্দ ও প্রয়োজনীয় প্রযুক্তিগত তথ্য।
• অ্যাপের কার্যকারিতা, ত্রুটি শনাক্তকরণ এবং নিরাপত্তা রক্ষার জন্য প্রয়োজনীয় লগ।
• আপনি কোন ফিচার ব্যবহার করছেন, সে সম্পর্কে সীমিত ব্যবহার-সংক্রান্ত তথ্য—যদি এমন বিশ্লেষণ ব্যবস্থা চালু থাকে।

গ. ডিভাইসে সংরক্ষিত তথ্য

আপনি কোনো কনটেন্ট অফলাইনে পড়া বা দেখার জন্য ডাউনলোড করলে সেটি আপনার ডিভাইসে সংরক্ষিত হতে পারে। অ্যাপের সেটিংস, থিম, ভাষা বা সেশন-সংক্রান্ত কিছু তথ্যও স্থানীয়ভাবে রাখা হতে পারে।

আমরা যে তথ্য সংগ্রহ করি, তা ব্যবহৃত ফিচার এবং আপনার অনুমতির ওপর নির্ভর করে। প্রয়োজনের অতিরিক্ত ব্যক্তিগত তথ্য সংগ্রহ না করার চেষ্টা করা হবে।

৩. আপনার তথ্য কেন ব্যবহার করা হয়

আপনার তথ্য নিম্নলিখিত উদ্দেশ্যে ব্যবহার করা হতে পারে:

• অ্যাকাউন্ট তৈরি, লগইন ও পরিচয় যাচাই করতে।
• গল্প পড়া, লেখা, প্রকাশ, সংরক্ষণ ও অনুসরণের সুবিধা দিতে।
• সার্চ, ফিড, প্রোফাইল, মন্তব্য, রিয়্যাকশন এবং অন্যান্য সামাজিক ফিচার পরিচালনা করতে।
• ছবি ও ভিডিও আপলোড, প্রদর্শন এবং অফলাইন সুবিধা চালু রাখতে।
• স্প্যাম, প্রতারণা, অপব্যবহার এবং অননুমোদিত কার্যকলাপ প্রতিরোধ করতে।
• অ্যাপের কর্মক্ষমতা উন্নত করতে এবং প্রযুক্তিগত সমস্যা সমাধান করতে।
• ব্যবহারকারীর রিপোর্ট পর্যালোচনা ও কমিউনিটি নীতিমালা বাস্তবায়ন করতে।
• প্রযোজ্য আইন ও বৈধ আইনি অনুরোধ অনুসরণ করতে।

৪. তথ্য কোথায় ও কীভাবে সংরক্ষণ করা হয়

গল্পঘরের প্রযুক্তিগত কাঠামো অনুযায়ী তথ্য নিম্নলিখিত ধরনের সেবায় সংরক্ষিত হতে পারে:

• অ্যাকাউন্ট ও ডেটাবেস: Supabase বা সমতুল্য ব্যাকএন্ড সেবা।
• ছবি, ভিডিও ও অন্যান্য মিডিয়া: Cloudflare R2 বা সমতুল্য স্টোরেজ সেবা।
• ডিভাইসের স্থানীয় স্টোরেজ: সেশন, পছন্দ এবং অফলাইনে ব্যবহারের জন্য ডাউনলোড করা কনটেন্ট।

প্রকৃতপক্ষে ব্যবহৃত সেবার ওপর ভিত্তি করে এই বিবরণ হালনাগাদ করা হবে। তথ্য যতদিন সেবা পরিচালনা, অ্যাকাউন্ট বজায় রাখা, নিরাপত্তা নিশ্চিত করা বা আইনি বাধ্যবাধকতা পূরণের জন্য প্রয়োজন, ততদিন সংরক্ষণ করা হতে পারে।

৫. তথ্য শেয়ার ও তৃতীয় পক্ষের সেবা

গল্পঘর আপনার ব্যক্তিগত তথ্য বিক্রি করে না। তবে সেবা পরিচালনার জন্য প্রয়োজন হলে সীমিত তথ্য নিম্নলিখিত পক্ষের সঙ্গে শেয়ার করা হতে পারে:

• প্রযুক্তি ও অবকাঠামো প্রদানকারী: ডেটাবেস, হোস্টিং, মিডিয়া স্টোরেজ এবং নিরাপত্তাসেবা পরিচালনার জন্য।
• আইনগত কর্তৃপক্ষ: প্রযোজ্য আইন অনুযায়ী বৈধ ও বাধ্যতামূলক অনুরোধের ক্ষেত্রে।
• নিরাপত্তা ও অধিকার সুরক্ষাসংক্রান্ত পক্ষ: প্রতারণা, গুরুতর অপব্যবহার বা অধিকার লঙ্ঘন মোকাবিলায় আইনসম্মতভাবে প্রয়োজন হলে।

তৃতীয় পক্ষের সেবা নিজস্ব শর্ত ও গোপনীয়তা নীতি অনুযায়ীও পরিচালিত হতে পারে।

৬. প্রকাশ্য প্রোফাইল ও কনটেন্ট

আপনি গল্পঘরে কোনো গল্প, মন্তব্য, প্রোফাইলের তথ্য বা ভিডিও প্রকাশ করলে সংশ্লিষ্ট ফিচারের সেটিংস অনুযায়ী অন্য ব্যবহারকারীরা তা দেখতে পারেন।

প্রকাশ্য কনটেন্ট অন্যরা পড়তে, দেখতে, শেয়ার করতে বা উদ্ধৃত করতে পারেন। কোনো কনটেন্ট মুছে ফেলার পরও অন্য ব্যবহারকারীর সংরক্ষিত কপি, স্ক্রিনশট বা বাহ্যিক শেয়ারের কপি থেকে যেতে পারে।

তাই প্রকাশের আগে ব্যক্তিগত বা গোপন তথ্য শেয়ার করার বিষয়ে সতর্ক থাকুন।

৭. আপনার অধিকার ও পছন্দ

প্রযোজ্য আইন ও প্রযুক্তিগত সীমাবদ্ধতা সাপেক্ষে আপনি:

• নিজের প্রোফাইল দেখতে ও সম্পাদনা করতে পারবেন।
• উপলভ্য সেটিংসের মাধ্যমে নিজের তথ্য নিয়ন্ত্রণ করতে পারবেন।
• অ্যাকাউন্ট বন্ধ বা মুছে ফেলার অনুরোধ করতে পারবেন।
• নিজের প্রকাশিত কনটেন্ট মুছে ফেলা বা সংশোধনের অনুরোধ করতে পারবেন।
• ডিভাইসে সংরক্ষিত অফলাইন কনটেন্ট মুছে ফেলতে পারবেন।
• আপনার তথ্য ব্যবহারের বিষয়ে প্রশ্ন করতে বা প্রযোজ্য অধিকার প্রয়োগের অনুরোধ জানাতে পারবেন।

কিছু তথ্য আইনগত, নিরাপত্তা বা বৈধ রেকর্ড সংরক্ষণের কারণে নির্দিষ্ট সময় পর্যন্ত রাখা প্রয়োজন হতে পারে।

৮. কুকি, স্থানীয় স্টোরেজ ও বিশ্লেষণ

অ্যাপের কার্যকারিতা বজায় রাখতে স্থানীয় স্টোরেজ, সেশন ব্যবস্থাপনা এবং প্রয়োজনীয় প্রযুক্তি ব্যবহার করা হতে পারে। ওয়েব সংস্করণ চালু হলে সেখানে প্রয়োজন অনুযায়ী কুকি বা অনুরূপ প্রযুক্তি ব্যবহৃত হতে পারে।

বিশ্লেষণ, পারফরম্যান্স পর্যবেক্ষণ বা অতিরিক্ত ট্র্যাকিং ফিচার চালু করা হলে তার প্রকৃতি অনুযায়ী এই নীতি হালনাগাদ করা হবে।

৯. তথ্যের নিরাপত্তা

আপনার তথ্য সুরক্ষিত রাখতে যুক্তিসংগত প্রযুক্তিগত ও সাংগঠনিক ব্যবস্থা গ্রহণ করা হবে। তবে ইন্টারনেটভিত্তিক কোনো ব্যবস্থা সম্পূর্ণ ঝুঁকিমুক্ত নয়। তাই সর্বোচ্চ সতর্কতা অবলম্বন করা হলেও শতভাগ নিরাপত্তার নিশ্চয়তা দেওয়া সম্ভব নয়।

আপনার অ্যাকাউন্টে সন্দেহজনক কার্যকলাপ দেখা গেলে দ্রুত আমাদের সঙ্গে যোগাযোগ করুন।

১০. শিশু ও কিশোর ব্যবহারকারী

গল্পঘর ব্যবহারের ক্ষেত্রে প্রযোজ্য বয়সসীমা, শিশু সুরক্ষা এবং অভিভাবকের সম্মতি-সংক্রান্ত আইন অনুসরণ করা হবে। কোনো ফিচার ব্যবহারের জন্য বয়সসীমা বা অতিরিক্ত যাচাই প্রয়োজন হলে তা সংশ্লিষ্ট নিয়ম অনুযায়ী নির্ধারণ করা হবে।

প্রযোজ্য আইন লঙ্ঘন করে কোনো শিশুর ব্যক্তিগত তথ্য সংগ্রহ করা হয়েছে বলে জানা গেলে যথাযথ ব্যবস্থা নেওয়া হবে।

১১. বিজ্ঞাপন ও ভবিষ্যৎ সেবা

গল্পঘরে বর্তমানে বা ভবিষ্যতে বিজ্ঞাপন, প্রিমিয়াম সাবস্ক্রিপশন কিংবা অন্যান্য অর্থায়ন-সংক্রান্ত ফিচার যুক্ত হতে পারে।

এ ধরনের ফিচার চালু হলে প্রযোজ্য ক্ষেত্রে বিজ্ঞাপন প্রদানকারী, পেমেন্ট প্রসেসর, সংগৃহীত তথ্যের ধরন এবং তথ্য ব্যবহারের উদ্দেশ্য সম্পর্কে প্রয়োজনীয় তথ্য এই নীতিতে বা সংশ্লিষ্ট নোটিশে জানানো হবে।

১২. নীতিমালার পরিবর্তন

সেবার ফিচার, প্রযুক্তি বা আইনি প্রয়োজন পরিবর্তিত হলে এই গোপনীয়তা নীতি হালনাগাদ করা হতে পারে। গুরুত্বপূর্ণ পরিবর্তনের ক্ষেত্রে যুক্তিসংগত উপায়ে আপনাকে জানানো হবে।

প্রতিটি সংস্করণের সর্বশেষ আপডেটের তারিখ এই পাতায় উল্লেখ থাকবে।

১৩. যোগাযোগ

গোপনীয়তা, ব্যক্তিগত তথ্য, অ্যাকাউন্ট বা তথ্য মুছে ফেলার বিষয়ে যোগাযোগ করুন:

ইমেইল: support@golpoghor.app
অ্যাপ: গল্পঘর → সেটিংস → সহায়তা ও যোগাযোগ

আমরা আপনার অনুরোধ পর্যালোচনা করে যুক্তিসংগত সময়ের মধ্যে উত্তর দেওয়ার চেষ্টা করব।
''';
  
  // ============================================================
  // TERMS — English
  // ============================================================
  static const _termsEn = '''
Terms of Use
GolpoGhor
Last updated: October 10, 2026

Welcome to GolpoGhor. By using GolpoGhor, you agree to these Terms of Use. If you do not agree with any part of these terms, please refrain from using the related services.

The purpose of these Terms is to ensure a safe, respectful and creative environment for readers, writers, viewers and the platform alike.

1. GolpoGhor Service

GolpoGhor is a Bengali literature and digital content platform. Based on the available features and permissions, users may:

• Read stories, novels and serialized episodes.
• Publish their own work through approved features.
• View or publish videos and other supported media.
• Follow writers and other users.
• Use comments, reactions, bookmarks and other interactions.

Not all features may be equally available to all users.

2. Account and User Responsibility

By using GolpoGhor, you agree that you will:

• Provide accurate and necessary information during registration.
• Protect your login credentials and account security.
• Remain alert to activity occurring on your own account.
• Not access other accounts without authorization or commit identity fraud.
• Not engage in spam, deception, harassment or obstruction of normal platform operation.

If your account security is compromised, notify us as soon as possible.

3. Content Ownership and Copyright

Your creation, your rights.

You retain your existing ownership and intellectual property rights over the original stories, novels, writings, videos, images or other content you create on GolpoGhor.

However, by publishing content, you grant GolpoGhor a limited, non-exclusive license to host, store, display, prepare in formats and distribute it on the platform according to your selected features. This license applies solely for operating the service and providing your chosen publishing features.

This does not transfer ownership of your content to GolpoGhor.

You agree that you will:

• Not publish others' writings, videos, images or works under your own name without permission.
• Not infringe copyright, trademarks or other legal rights of others.
• Not commercially use others' content without proper permission.
• Be responsible for ensuring the rights and permissions of your published content.

4. Content Publishing and Moderation

GolpoGhor will work to maintain a safe and respectful environment. The following types of content may be prohibited or restricted:

• Illegal, deceptive or rights-infringing content.
• Hate speech, credible threats or targeted harassment.
• Personal or confidential information published without permission.
• Malware, harmful links, spam or deceptive promotion.
• Content violating applicable law or platform policies.
• Content violating applicable age limits or child protection laws.

Content may temporarily be limited, removed or held for review when necessary. In cases of serious or repeated violations, restrictions may be imposed on the account.

5. Video Publishing Rules

Video publishing features may be limited to approved users or designated accounts.

When uploading a video, you must ensure that:

• You have the necessary rights or permission to publish the video.
• The video does not unnecessarily violate others' privacy, safety or legal rights.
• The video's title, description, tags and other information are as accurate as possible.
• The video follows GolpoGhor's content policies and applicable law.

GolpoGhor may review, restrict or remove videos when necessary.

6. Comments, Following and Social Conduct

When using GolpoGhor's social features, you must maintain respect toward other users.

Threatening anyone, personally attacking, harassing, repeatedly sending unwanted messages or disrupting others' normal use is not acceptable.

You may disagree with other users' opinions or published content; however, insults, threats or harmful behavior due to disagreement are not acceptable.

7. Downloads and Offline Use

If the download feature is available, it is provided for personal and approved use.

Without the author's or rights holder's permission and applicable law, downloaded content may not be redistributed, commercially sold, republished under your own name or re-uploaded to another platform.

A content being available offline does not mean its copyright has become yours.

8. Reports, Complaints and Copyright Claims

If you believe any content is violating the rules, is harassing or is infringing your intellectual property rights, you may report it via the app's report feature or the designated support address.

Additional information may be requested to review the complaint. Action will be taken according to applicable law. Where appropriate, the related content may be limited, removed or the related user's account may be reviewed.

9. Advertising, Premium Features and Payments

GolpoGhor may in the future introduce advertising, subscriptions, premium benefits or paid content access.

When such features are introduced, pricing, billing period, renewal, cancellation, refunds and other applicable terms will be communicated through the relevant feature.

Before launching any paid feature, applicable terms and laws will be followed.

10. Service Availability and Limitation of Liability

GolpoGhor will make reasonable efforts to keep the service uninterrupted and error-free. However, temporary disruptions may occur due to maintenance, technical issues, network failures or third-party services.

Opinions, stories or videos published by users on the platform do not always reflect GolpoGhor's own views.

To the extent permitted by applicable law, liability for damages arising from the use of or temporary unavailability of the service may be limited. However, liability that cannot be excluded or limited under law will not be affected by this clause.

11. Account Suspension or Termination

If these Terms, content policies or applicable law are violated, GolpoGhor may take appropriate action. Depending on the situation, warnings, limiting certain features, content removal, temporary suspension or closure of the account may occur.

Users may also request to close their own account through the applicable procedure. Even after account closure, some information may be retained for a limited time due to legal or security reasons.

12. Changes to the Terms

These Terms may be updated due to new features, technical changes or legal requirements. Significant changes will be communicated to users in a reasonable manner.

The latest version and update date will be published on this page.

13. Applicable Law

GolpoGhor's service and these Terms will be governed by applicable law. Any dispute will be resolved according to applicable law.

14. Contact

For Terms, copyright, reports or other complaints:

Email: support@golpoghor.app
App: GolpoGhor → Settings → Help & Contact

Your cooperation is appreciated in building GolpoGhor as a safe, creative and respectful platform for everyone.
''';

  // ============================================================
  // PRIVACY — English
  // ============================================================
  static const _privacyEn = '''
Privacy Policy
GolpoGhor
Last updated: October 10, 2026

Welcome to GolpoGhor. GolpoGhor is a digital platform where readers read stories, writers express their creativity and users gain new experiences through literature and video content.

The privacy, security and respect for your creative work are important to us. This Privacy Policy explains what type of information GolpoGhor may collect, why it uses it, how it stores it and what rights you have.

1. About GolpoGhor

GolpoGhor is a digital platform for publishing and enjoying Bengali stories, novels, serialized literature and approved video content. This policy applies to the GolpoGhor app, related online services and other applicable digital features.

2. What Type of Information We Collect

To operate the service, improve user experience and maintain platform security, we may collect the following types of information.

A. Information You Provide

• Name, email address, nickname and profile picture during account creation.
• Optional bio or other information added to your profile.
• Stories, novels, episodes, videos, captions, tags and other media you upload.
• Comments, reactions, bookmarks, follows and other activities you perform.

B. Information Collected Automatically

• Login sessions, app preferences and necessary technical information.
• Logs required for app functionality, error detection and security.
• Limited usage information about which features you use—if such analytics is enabled.

C. Information Stored on the Device

If you download content for offline reading or viewing, it may be stored on your device. Some settings, theme, language or session-related information may also be stored locally.

The information we collect depends on the features used and your permissions. We try not to collect more personal information than necessary.

3. Why Your Information Is Used

Your information may be used for the following purposes:

• To create accounts, log in and verify identity.
• To provide features for reading, writing, publishing, saving and following.
• To operate search, feed, profile, comments, reactions and other social features.
• To enable image and video upload, display and offline functionality.
• To prevent spam, deception, misuse and unauthorized activity.
• To improve app performance and resolve technical issues.
• To review user reports and enforce community policies.
• To follow applicable law and valid legal requests.

4. Where and How Information Is Stored

Based on GolpoGhor's technical infrastructure, information may be stored in the following types of services:

• Accounts and database: Supabase or equivalent backend services.
• Images, videos and other media: Cloudflare R2 or equivalent storage services.
• Local device storage: Sessions, preferences and downloaded content for offline use.

This description will be updated based on the services actually used. Information may be retained as long as necessary to operate the service, maintain accounts, ensure security or meet legal obligations.

5. Information Sharing and Third-Party Services

GolpoGhor does not sell your personal information. However, when necessary to operate the service, limited information may be shared with the following parties:

• Technology and infrastructure providers: To operate databases, hosting, media storage and security services.
• Legal authorities: In the case of valid and mandatory requests under applicable law.
• Security and rights protection parties: When legally necessary to address fraud, serious misuse or rights infringement.

Third-party services may also operate under their own terms and privacy policies.

6. Public Profile and Content

If you publish any story, comment, profile information or video on GolpoGhor, other users may see it according to the relevant feature settings.

Public content may be read, viewed, shared or quoted by others. Even after deleting content, copies saved by other users, screenshots or external shares may remain.

Therefore, be careful about sharing personal or confidential information before publishing.

7. Your Rights and Choices

Subject to applicable law and technical limitations, you may:

• View and edit your own profile.
• Control your information through available settings.
• Request account closure or deletion.
• Request deletion or correction of your published content.
• Delete offline content stored on your device.
• Ask questions about your information use or request applicable rights.

Some information may need to be kept for a certain period due to legal, security or valid record-keeping reasons.

8. Cookies, Local Storage and Analytics

To maintain app functionality, local storage, session management and necessary technologies may be used. If a web version is launched, cookies or similar technologies may be used as needed.

If analytics, performance monitoring or additional tracking features are introduced, this policy will be updated according to their nature.

9. Information Security

Reasonable technical and organizational measures will be taken to keep your information safe. However, no internet-based system is completely risk-free. Therefore, even with the highest precautions, 100% security cannot be guaranteed.

If you notice suspicious activity on your account, contact us promptly.

10. Children and Adolescent Users

Applicable age limits, child protection and parental consent laws will be followed regarding GolpoGhor use. If age limits or additional verification are required for any feature, they will be set according to the relevant rules.

If it is learned that a child's personal information has been collected in violation of applicable law, appropriate action will be taken.

11. Advertising and Future Services

GolpoGhor may currently or in the future include advertising, premium subscriptions or other monetization features.

When such features are introduced, necessary information about advertisers, payment processors, the type of information collected and the purpose of information use will be communicated in this policy or the relevant notice.

12. Changes to the Policy

This Privacy Policy may be updated if service features, technology or legal requirements change. Significant changes will be communicated to you in a reasonable manner.

The latest update date of each version will be mentioned on this page.

13. Contact

For privacy, personal information, account or information deletion matters, contact:

Email: support@golpoghor.app
App: GolpoGhor → Settings → Help & Contact

We will try to review your request and respond within a reasonable time.
''';
}
