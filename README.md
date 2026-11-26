# গল্পঘর (GolpoGhor)

বাংলা গল্প, উপন্যাস ও ভিডিও প্ল্যাটফর্ম।

## Stack
- Flutter + Riverpod + go_router
- Supabase (Auth, DB, RLS, Edge Functions, Realtime)
- Cloudflare R2 (মিডিয়া — **presigned URL**, ক্লায়েন্টে কোনো R2 secret নেই)
- বাংলা + ইংরেজি

## Architecture
```text
Flutter App
  ├── Supabase Auth / Postgres / Realtime
  ├── Edge Function: create-upload-url  → R2 presigned PUT
  ├── Edge Function: delete-object      → R2 delete
  └── R2 public URL দিয়ে মিডিয়া দেখানো।

Inbox ট্যাব = in-app নোটিফিকেশন (Realtime + local notification)।
অ্যাপ কিলড অবস্থায় OS পুশের জন্য পরে FCM যোগ করা যায়; এখন Firebase ছাড়াই Inbox + foreground/background ব্যানার কাজ করে।

GitHub Actions Secrets
Secret প্রয়োজন
SUPABASE_URL হ্যাঁ
SUPABASE_ANON_KEY হ্যাঁ
R2_ACCOUNT_ID হ্যাঁ
R2_PUBLIC_BASE_URL হ্যাঁ
R2_BUCKET হ্যাঁ (ডিফল্ট golpoghor)

R2_ACCESS_KEY / R2_SECRET_KEY শুধু Supabase Edge Function Secrets এ — GitHub/APK তে নয়।

Setup

1. এই রিপো আপলোড / push
2. supabase/sql/01_rls_policies.sql SQL Editor এ রান
3. Edge Functions ডিপ্লয় + secrets সেট
4. GitHub Secrets সেট → Actions দিয়ে APK

লোকাল রান
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=R2_ACCOUNT_ID=... \
  --dart-define=R2_PUBLIC_BASE_URL=... \
  --dart-define=R2_BUCKET=golpoghor

Edge Function deploy (CLI)
supabase functions deploy create-upload-url
supabase functions deploy delete-object
supabase secrets set R2_ACCESS_KEY=... R2_SECRET_KEY=... R2_ACCOUNT_ID=... R2_BUCKET=golpoghor R2_PUBLIC_BASE_URL=...

---

### ৩. `.github/workflows/flutter-ci.yml` (Sentry বাদ দেওয়া হয়েছে)
```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Create Android platform if missing
        run: |
          echo "Checking android folder..."
          ls -la
          if [ ! -d android ]; then
            echo "android/ missing — running flutter create"
            flutter create . --project-name golpoghor --org com.golpoghor --platforms=android
          elif [ ! -f android/app/build.gradle ] && [ ! -f android/app/build.gradle.kts ]; then
            echo "android/ incomplete — running flutter create"
            flutter create . --project-name golpoghor --org com.golpoghor --platforms=android
          else
            echo "android/ OK"
          fi
          ls -la android/app/ || true

      - name: Pin Kotlin plugin to 1.9.24
        run: |
          set -e
          if [ -f android/settings.gradle.kts ]; then
            sed -i -E 's/id\("org\.jetbrains\.kotlin\.android"\) version "[^"]+"/id("org.jetbrains.kotlin.android") version "1.9.24"/' android/settings.gradle.kts
            echo "---- settings.gradle.kts (kotlin lines) ----"
            grep -n "kotlin" android/settings.gradle.kts || true
          fi
          if [ -f android/settings.gradle ]; then
            sed -i -E "s/id 'org\.jetbrains\.kotlin\.android' version '[^']+'/id 'org.jetbrains.kotlin.android' version '1.9.24'/" android/settings.gradle
            sed -i -E 's/id\("org\.jetbrains\.kotlin\.android"\) version "[^"]+"/id("org.jetbrains.kotlin.android") version "1.9.24"/' android/settings.gradle
            echo "---- settings.gradle (kotlin lines) ----"
            grep -n "kotlin" android/settings.gradle || true
          fi

      - name: Update Kotlin Version in Gradle
        run: |
          if [ -f android/build.gradle ]; then
            sed -i 's/ext.kotlin_version = .*/ext.kotlin_version = "1.9.24"/' android/build.gradle
          elif [ -f android/build.gradle.kts ]; then
            sed -i 's/val kotlinVersion = .*/val kotlinVersion = "1.9.24"/' android/build.gradle.kts
          fi

      - name: Update Gradle Wrapper and Disable Lint
        run: |
          cd android
          # Gradle 8.7 ব্যবহার করা হয়েছে (Gradle 9.x নেই)
          sed -i 's|distributionUrl=.*|distributionUrl=https\\://services.gradle.org/distributions/gradle-8.7-all.zip|' gradle/wrapper/gradle-wrapper.properties

          if [ -f app/build.gradle ]; then
            echo -e "\nandroid {\n    lintOptions {\n        checkReleaseBuilds false\n        abortOnError false\n    }\n}" >> app/build.gradle
          elif [ -f app/build.gradle.kts ]; then
            echo -e "\nandroid {\n    lint {\n        checkReleaseBuilds = false\n        abortOnError = false\n    }\n}" >> app/build.gradle.kts
          fi
          cd ..

      - name: Ensure INTERNET permission and GolpoGhor Label
        run: |
          MANIFEST=android/app/src/main/AndroidManifest.xml
          if [ -f "$MANIFEST" ]; then
            if ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
              sed -i 's|<manifest\(.*\)>|<manifest\1>\n    <uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>|' "$MANIFEST"
            fi
            # ✅ অ্যাপের নাম GolpoGhor করা হলো
            sed -i 's/android:label="[^"]*"/android:label="GolpoGhor"/' "$MANIFEST"
          else
            echo "Manifest NOT found!"
            exit 1
          fi

      - name: Enable Core Library Desugaring
        run: |
          python3 << 'PY'
          from pathlib import Path

          desugar = "com.android.tools:desugar_jdk_libs:2.1.4"
          kts = Path("android/app/build.gradle.kts")
          groovy = Path("android/app/build.gradle")

          def patch_kts(text: str) -> str:
              if "isCoreLibraryDesugaringEnabled" not in text:
                  if "compileOptions {" in text:
                      text = text.replace(
                          "compileOptions {",
                          "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
                          1,
                      )
                  else:
                      text = text.replace(
                          "android {",
                          "android {\n    compileOptions {\n"
                          "        isCoreLibraryDesugaringEnabled = true\n"
                          "        sourceCompatibility = JavaVersion.VERSION_17\n"
                          "        targetCompatibility = JavaVersion.VERSION_17\n"
                          "    }",
                          1,
                      )
              if "desugar_jdk_libs" not in text:
                  if "dependencies {" in text:
                      text = text.replace(
                          "dependencies {",
                          f'dependencies {{\n    coreLibraryDesugaring("{desugar}")',
                          1,
                      )
                  else:
                      text += f'\n\ndependencies {{\n    coreLibraryDesugaring("{desugar}")\n}}\n'
              return text

          def patch_groovy(text: str) -> str:
              if "coreLibraryDesugaringEnabled" not in text:
                  if "compileOptions {" in text:
                      text = text.replace(
                          "compileOptions {",
                          "compileOptions {\n        coreLibraryDesugaringEnabled true",
                          1,
                      )
                  else:
                      text = text.replace(
                          "android {",
                          "android {\n    compileOptions {\n"
                          "        coreLibraryDesugaringEnabled true\n"
                          "        sourceCompatibility JavaVersion.VERSION_17\n"
                          "        targetCompatibility JavaVersion.VERSION_17\n"
                          "    }",
                          1,
                      )
              if "desugar_jdk_libs" not in text:
                  if "dependencies {" in text:
                      text = text.replace(
                          "dependencies {",
                          f'dependencies {{\n    coreLibraryDesugaring "{desugar}"',
                          1,
                      )
                  else:
                      text += f'\n\ndependencies {{\n    coreLibraryDesugaring "{desugar}"\n}}\n'
              return text

          if kts.exists():
              print("Patching", kts)
              kts.write_text(patch_kts(kts.read_text(encoding="utf-8")), encoding="utf-8")
          elif groovy.exists():
              print("Patching", groovy)
              groovy.write_text(patch_groovy(groovy.read_text(encoding="utf-8")), encoding="utf-8")
          else:
              print("No android/app build.gradle found")
              raise SystemExit(1)
          PY

      - name: Pub get
        run: flutter pub get

      - name: Generate launcher icons
        run: dart run flutter_launcher_icons || true

      - name: Analyze (fail only on real errors)
        run: |
          set +e
          OUT=$(flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1)
          CODE=$?
          echo "$OUT"
          if echo "$OUT" | grep -E "error •" >/dev/null; then
            echo "Analyzer reported error-level issues"
            exit 1
          fi
          echo "Analyze OK (no error-level issues, exit was $CODE)"
          exit 0

      - name: Test (fail on error)
        run: flutter test

      - name: Build release APK (obfuscated)
        run: |
          flutter build apk --release \
            --obfuscate \
            --split-debug-info=build/debug-info \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} \
            --dart-define=R2_ACCOUNT_ID=${{ secrets.R2_ACCOUNT_ID }} \
            --dart-define=R2_PUBLIC_BASE_URL=${{ secrets.R2_PUBLIC_BASE_URL }} \
            --dart-define=R2_BUCKET=${{ secrets.R2_BUCKET }}

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: golpoghor-release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          if-no-files-found: error
