# গল্পঘর (GolpoGhor)

বাংলা গল্প ও ধারাবাহিক উপন্যাস প্ল্যাটফর্ম।

## Stack
- Flutter + Riverpod + go_router
- Supabase (Auth, DB)
- Cloudflare R2 (মিডিয়া)
- Google Sign-In

## Setup
1. Flutter SDK
2. `flutter pub get`
3. Supabase URL/anon: `lib/core/constants/supabase_constants.dart`
4. R2 keys (ল্যাপটপ): `--dart-define=R2_ACCESS_KEY=... --dart-define=R2_SECRET_KEY=...`
5. `flutter run`

## V1 Features
Auth (Google + Email), প্রোফাইল, ফিড, সার্চ, গল্প/উপন্যাস, রিডার, ডাউনলোড, সোশ্যাল, অ্যাডমিন
