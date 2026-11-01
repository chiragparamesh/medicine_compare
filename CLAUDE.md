# CLAUDE.md — MediCompare (`medicine_compare`)

Context for future Claude Code sessions. Read this before changing anything.

Owner: Chirag (final-year AIML engineering student). This is a resume project.
GitHub: https://github.com/chiragparamesh/medicine_compare (public). Org / package: `com.chirag.medicine_compare`.

## Project brief

### 1. medicine_compare — "MediCompare" (resume project)

**Problem:** the same medicines cost different amounts on different pharmacy apps, and doctors' handwriting is hard to read.

**Vision:** the user photographs a prescription; a handwriting model (TrOCR fine-tuned in Colab, with output restricted to real Indian medicine names through fuzzy matching against a medicine database) reads the medicines into an editable cart. The user confirms the cart. The app compares the final price, including delivery fees and the best coupon, across Tata 1mg, PharmEasy, Netmeds, Apollo 24/7 and Truemeds, shows the cheapest platform and a cheaper generic alternative, and deep-links to that platform. Future: in-app login to each platform so prices include the user's own coupons.

**Current build scope:** camera/gallery picker, a placeholder OCR service behind a clean interface, editable cart, prices from a bundled mock JSON for the 5 platforms, coupon rule engine (percent, flat, max cap, min order, first order), results screen ranking platforms.

## Lightweight rules

My Windows laptop has low RAM: Android Studio and the Android emulator froze it. Everything must stay lightweight:

- No Android Studio, no emulator, no local Gradle/APK builds.
- Daily preview with: `flutter run -d chrome`
- APKs are built by GitHub Actions and installed on my Pixel 9a.
- ML models are trained in Google Colab; only the exported .tflite files live in the project.
- Everything goes inside `D:\Projects`. Nothing else on `D:\` root.
- Never run Gradle or `flutter build apk` locally.
- One install / one heavy task at a time. Never run parallel heavy tasks.
- `android/gradle.properties` stays capped: `org.gradle.jvmargs=-Xmx1536m`, `org.gradle.daemon=false`, `org.gradle.parallel=false`.
- Toolchain lives in `D:\Projects\_tools` (flutter, jdk, android-sdk, caches\pub, caches\gradle).

## How to work in this repo

- Preview: `flutter run -d chrome` (web is the dev target; Android is built only by CI).
- Checks you may run locally: `flutter pub get`, `flutter analyze`, `flutter test`.
- Never run: `flutter build apk`, `./gradlew`, `flutter run -d <android device>` with a local build, or anything that starts Gradle.
- APK: push to GitHub → Actions → "Build APK" → download the `medicine_compare-release-apk` artifact → install on the Pixel 9a.
- Plugins that don't support web (camera, tflite, GPS, haptics, …) must sit behind an interface in `lib/core/services/` with a web/mock implementation so Chrome preview keeps working.

## Structure

- `lib/main.dart`, `lib/app.dart` — entry point and `MaterialApp.router`.
- `lib/core/theme/` — theme and colors. `lib/core/router/` — go_router routes.
- `lib/core/services/` — platform/service interfaces. `lib/core/utils/` — constants, helpers. `lib/core/widgets/` — shared widgets.
- `lib/features/<feature>/{data,domain,presentation}/` — one folder per feature:
  - `lib/features/prescription_scan/` — Camera / gallery picker for the prescription photo
  - `lib/features/ocr/` — OCR service interface + placeholder (TrOCR later)
  - `lib/features/cart/` — Editable medicine cart the user confirms
  - `lib/features/pricing/` — Bundled mock prices for 1mg, PharmEasy, Netmeds, Apollo 24/7, Truemeds
  - `lib/features/coupons/` — Coupon rule engine: percent, flat, max cap, min order, first order
  - `lib/features/results/` — Results screen ranking platforms + cheaper generic
- `ml/` — Colab workflow notes. Only exported `.tflite` files are committed, in `assets/models/`.
- `docs/architecture.md` — full system design and roadmap. Keep it updated.
- `.github/workflows/build-apk.yml` — the only place APKs are built.

## Status

Skeleton only: folders, theme, router, placeholder home screen, CI. No features built yet.
Update the features table in README.md (Built / Planned) as features land.
