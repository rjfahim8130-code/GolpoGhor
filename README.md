# গল্পঘর (GolpoGhor)

বাংলা গল্প, উপন্যাস ও ভিডিও প্ল্যাটফর্ম।

## Stack
- Flutter + Riverpod + go_router
- Supabase (Auth, DB, RLS)
- Cloudflare R2 (মিডিয়া — presigned URL দিয়ে)
- বাংলা + ইংরেজি (ভবিষ্যতে আরো)

## Architecture
Flutter App
   │
   ├── Supabase (Auth / Postgres / RLS / Edge Functions)
   │       └── Edge Function: create-upload-url → R2 presigned PUT
   │
   └── Cloudflare R2 (মিডিয়া স্টোরেজ — ক্লায়েন্টে কোনো secret নেই)

## প্রয়োজনীয় Environment / Secrets

GitHub → Settings → Secrets and variables → Actions এ যোগ করো:

| Secret Name | কোথায় পাবে |
|-------------|-------------|
| `SUPABASE_URL` | Supabase Dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Project Settings → API |
| `SENTRY_DSN` | sentry.io → Project → Client Keys |
| `R2_ACCOUNT_ID` | Cloudflare Dashboard → R2 → Overview |
| `R2_PUBLIC_BASE_URL` | Cloudflare R2 → Bucket → Public URL |

> ⚠️ `R2_ACCESS_KEY` / `R2_SECRET_KEY` **শুধু Supabase Edge Function Secrets এ** থাকবে, GitHub এ নয়, APK তে নয়।

## Setup (লোকাল)
1. Flutter SDK 3.3+
2. `flutter pub get`
3. Secrets ছাড়া run করতে:
   flutter run 
     --dart-define=SUPABASE_URL=... 
     --dart-define=SUPABASE_ANON_KEY=... 
     --dart-define=R2_ACCOUNT_ID=... 
     --dart-define=R2_PUBLIC_BASE_URL=...

   
## CI/CD
- `main` এ push → GitHub Actions → APK build (obfuscated)
- APK artifact: Actions → run → Artifacts

## Security নোট
- **RLS সব টেবিলে চালু** থাকতে হবে
- Admin write শুধু `is_admin=true` RLS policy / RPC দিয়ে
- R2 secret কখনো ক্লায়েন্টে না — Edge Function + presigned URL
- `service_role` key কখনো Flutter কোডে না

## Features
- Auth: Email/Password
- হোম ফিড, আবিষ্কার, জনপ্রিয়, ট্রেন্ডিং, ক্যাটাগরি
- সার্চ (গল্প/উপন্যাস/লেখক/ভিডিও)
- রিডার (গল্প + উপন্যাস পর্ব)
- লেখা (খসড়া সাপোর্ট)
- ভিডিও ফিড (reels স্টাইল)
- প্রোফাইল, কমেন্ট, রিপ্লাই (@mention)
- ডাউনলোড (অফলাইন)
- থিম, ভাষা (বাংলা/ইংরেজি)
- অ্যাডমিন ড্যাশবোর্ড, রিপোর্ট সিস্টেম
- নোটিফিকেশন (২ দিন পর অটো-ডিলিট)
  
