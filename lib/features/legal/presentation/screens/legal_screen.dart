import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LegalScreen extends StatelessWidget {
  final String type; // terms | privacy

  const LegalScreen({super.key, required this.type});

  bool get _isTerms => type == 'terms';

  String get _title => _isTerms ? 'শর্তাবলী' : 'প্রাইভেসি পলিসি';

  String get _bodyBn => _isTerms ? _termsBn : _privacyBn;

  String get _bodyEn => _isTerms ? _termsEn : _privacyEn;

  static const _termsBn = '''
গল্পঘর (GolpoGhor) ব্যবহারের শর্তাবলী

১. সেবা
গল্পঘর একটি বাংলা গল্প, উপন্যাস ও ভিডিও প্ল্যাটফর্ম। এক অ্যাকাউন্টেই পাঠক, লেখক ও দর্শক হওয়া যায়।

২. অ্যাকাউন্ট
আপনি সঠিক তথ্য দিয়ে অ্যাকাউন্ট তৈরি করবেন। অ্যাকাউন্টের নিরাপত্তা আপনার দায়িত্ব।

৩. কনটেন্ট
লেখক নিজের লেখার অধিকার রাখেন। অন্যের কপিরাইট লঙ্ঘন নিষিদ্ধ। অশ্লীল, হিংসা বা অবৈধ কনটেন্ট সরানো হতে পারে।

৪. ব্যবহার
স্প্যাম, হয়রানি বা অন্যের অ্যাকাউন্টে অনুপ্রবেশ নিষিদ্ধ।

৫. দায়
প্ল্যাটফর্ম "যেমন আছে" ভিত্তিতে দেওয়া হয়। লেখকের মতামত অ্যাপের মতামত নয়।

৬. পরিবর্তন
শর্তাবলী সময় সময় আপডেট হতে পারে। চালিয়ে ব্যবহার মানে নতুন শর্ত মেনে নেওয়া।
''';

  static const _termsEn = '''
GolpoGhor Terms of Use

1. Service — A Bengali story, novel and video platform for readers, writers and viewers.
2. Account — Provide accurate info; you are responsible for account security.
3. Content — Authors retain rights to their work. Copyright infringement and illegal content are prohibited and may be removed.
4. Conduct — No spam, harassment, or unauthorized access.
5. Liability — Service is provided as-is. Author views are not those of the app.
6. Changes — Terms may be updated; continued use means acceptance.
''';

  static const _privacyBn = '''
গল্পঘর প্রাইভেসি পলিসি

১. আমরা কী সংগ্রহ করি
ইমেইল, নাম, প্রোফাইল তথ্য, এবং আপনার লেখা/ইন্টারঅ্যাকশন (কমেন্ট, রিঅ্যাকশন, বুকমার্ক)।

২. কেন
অ্যাকাউন্ট চালু, ফিড, সার্চ এবং সার্ভিস উন্নত করতে।

৩. শেয়ার
আইনগত দাবি ছাড়া তৃতীয় পক্ষের কাছে ব্যক্তিগত তথ্য বিক্রি করা হয় না।

৪. স্টোরেজ
ডেটা Supabase ও (মিডিয়া) Cloudflare R2-তে থাকতে পারে।

৫. অধিকার
প্রোফাইল এডিট/মুছে ফেলার অনুরোধ সাপোর্টে জানাতে পারেন।

৬. কুকি / লোকাল
অ্যাপ সেশন ও অফলাইন ডাউনলোড ডিভাইসে রাখতে পারে।
''';

  static const _privacyEn = '''
GolpoGhor Privacy Policy

1. We collect email, profile data, and interaction data needed for the service.
2. Used to operate accounts, feed, search, and improve the app.
3. We do not sell personal data; disclosure only if legally required.
4. Data may be stored on Supabase and Cloudflare R2 for media.
5. You may request profile updates or account deletion via support.
6. Session and offline downloads may be stored on your device.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _bodyBn,
            style: const TextStyle(height: 1.55, fontSize: 15),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'English',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _bodyEn,
            style: const TextStyle(height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
