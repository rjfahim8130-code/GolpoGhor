# গল্পঘর (GolpoGhor)

বাংলা গল্প, উপন্যাস ও ভিডিও প্ল্যাটফর্ম।

## Stack
- Flutter + Riverpod + go_router
- Supabase (Auth, DB, RLS, Edge Functions, Realtime)
- Cloudflare R2 (মিডিয়া — **presigned URL**, ক্লায়েন্টে কোনো R2 secret নেই)
- Sentry (ক্র্যাশ রিপোর্ট)
- বাংলা + ইংরেজি

## Architecture
```
Flutter App
  ├── Supabase Auth / Postgres / Realtime
  ├── Edge Function: create-upload-url  → R2 presigned PUT
  ├── Edge Function: delete-object      → R2 delete
  └── R2 public URL দিয়ে মিডিয়া দেখানো
```

Inbox ট্যাব = in-app নোটিফিকেশন (Realtime + local notification)।  
অ্যাপ কিলড অবস্থায় OS পুশের জন্য পরে FCM যোগ করা যায়; এখন Firebase ছাড়াই Inbox + foreground/background ব্যানার কাজ করে।

## GitHub Actions Secrets
| Secret | প্রয়োজন |
|--------|----------|
| SUPABASE_URL | হ্যাঁ |
| SUPABASE_ANON_KEY | হ্যাঁ |
| SENTRY_DSN | ঐচ্ছিক |
| R2_ACCOUNT_ID | হ্যাঁ |
| R2_PUBLIC_BASE_URL | হ্যাঁ |
| R2_BUCKET | হ্যাঁ (ডিফল্ট golpoghor) |

**R2_ACCESS_KEY / R2_SECRET_KEY শুধু Supabase Edge Function Secrets এ** — GitHub/APK তে নয়।

## Setup
1. এই রিপো আপলোড / push
2. `supabase/sql/01_rls_policies.sql` SQL Editor এ রান
3. Edge Functions ডিপ্লয় + secrets সেট
4. GitHub Secrets সেট → Actions দিয়ে APK

### লোকাল রান
```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=R2_ACCOUNT_ID=... \
  --dart-define=R2_PUBLIC_BASE_URL=... \
  --dart-define=R2_BUCKET=golpoghor
```

### Edge Function deploy (CLI)
```bash
supabase functions deploy create-upload-url
supabase functions deploy delete-object
supabase secrets set R2_ACCESS_KEY=... R2_SECRET_KEY=... R2_ACCOUNT_ID=... R2_BUCKET=golpoghor R2_PUBLIC_BASE_URL=...
```
