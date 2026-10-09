# গল্পঘর (GolpoGhor)

বাংলা গল্প, উপন্যাস ও ভিডিও প্ল্যাটফর্ম।

## Stack
- Flutter + Riverpod + go_router
- Supabase (Auth, DB)
- Cloudflare R2 (মিডিয়া)
- বাংলা + ইংরেজি (ভবিষ্যতে আরো)

## Setup
1. Flutter SDK 3.3+
2. `flutter pub get`
3. Supabase URL/anon → `lib/core/constants/supabase_constants.dart`
4. R2 keys → `--dart-define=R2_ACCESS_KEY=... --dart-define=R2_SECRET_KEY=...`
5. `flutter run`

## Features
- Auth: Email/Password
- হোম ফিড (গল্প + উপন্যাস)
- আবিষ্কার, জনপ্রিয়, ট্রেন্ডিং, ক্যাটাগরি
- সার্চ (ক্রস-প্লাটফর্ম: গল্প/উপন্যাস/লেখক/ভিডিও)
- রিডার (একই UI গল্প ও উপন্যাস — উপন্যাসে আগের/পরের পর্ব)
- লেখা (একই UI গল্প ও উপন্যাস, খসড়া সাপোর্ট)
- ভিডিও ফিড (রিলস স্টাইল, admin toggle)
- প্রোফাইল (Facebook স্টাইল + ড্যাশবোর্ড)
- নোটিফিকেশন (in-app, ২ দিন পর অটো ডিলিট)
- কমেন্ট + রিপ্লাই (@mention)
- ডাউনলোড (শুধু অ্যাপে অফলাইনে)
- থিম (light/dark/system)
- ভাষা (বাংলা/ইংরেজি)
- অ্যাডমিন ড্যাশবোর্ড
- Report সিস্টেম
