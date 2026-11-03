# VANDARNA

Community archive of abandoned buildings in Varna, Bulgaria (Flutter, Android, Bulgarian UI).
Package: `com.vandarna.app`. State: `provider`. Map: `flutter_map` + CARTO/OpenStreetMap tiles (**no map API key needed**).

## Two modes
* **Demo mode (default)** – no Firebase values set. The app runs fully offline with clearly marked sample records; data stays on the phone. Accounts, Google sign-in and push are disabled.
* **Firebase mode** – set the repository secrets below and rebuild. Auth, Firestore, Storage, App Check and FCM token registration become active.

## Build the APK from your phone (no PC, no Android Studio)
1. Create a GitHub repository (GitHub app or mobile browser, "Desktop site" helps).
2. Unzip `VANDARNA.zip` on the phone and upload the files to the repo root (**Add file → Upload files**).
   Hidden folders (`.github`) are often skipped by phone file pickers, so also create
   `.github/workflows/build-apk.yml` via **Add file → Create new file** (type the path, paste the separate `build-apk.yml`).
3. Open **Actions → Build VANDARNA APK → Run workflow** (it also runs on every push to `main`).
4. When it finishes, open the run and download the artifact **VANDARNA-Android-APK** (contains `app-release.apk`). Install it (allow "install unknown apps").

The workflow pins Flutter 3.32.8, uses JDK 17, runs `flutter analyze` (errors fail the build; warnings/infos are reported only) and builds the release APK.

## Firebase setup (optional but needed for accounts)
1. Firebase console → create project → add Android app `com.vandarna.app`.
2. Enable **Authentication** (Email/Password + Google), **Firestore**, **Storage**, **App Check** (Play Integrity), **Cloud Messaging**.
3. Publish `firestore.rules` and `storage.rules` from this repo (Console → Rules).
4. Add these **GitHub secrets** (Settings → Secrets and variables → Actions):

| Secret | Where to find it |
|---|---|
| `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET` | Project settings → Your apps → Android |
| `GOOGLE_SERVER_CLIENT_ID` | Authentication → Google provider → Web client ID |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Optional upload/release keystore (base64 of the `.jks`) |

Google sign-in needs a **stable signing key**: add the keystore secrets, then register that key's SHA-1 in Firebase. Without them every build is debug-signed with a different key and Google sign-in will fail (email login still works).
Nothing secret is committed; values are injected with `--dart-define`.

## Community verification (no central admin)
* New buildings start as **Очаква проверка**; 3 confirmations from *other* users → **Проверена**.
* Authors cannot confirm their own submissions; one confirmation per user (also enforced in `firestore.rules`).
* ≥2 "остаряла" reports, or no confirmation for a year → **Информацията е остаряла**; ≥3 other reports → **Докладвана**.
* Spam protection: max 3 submissions / 24 h per user, duplicate detection (same name or < 50 m), App Check, size/type limits in rules.
  A server-side rate limit and automated moderation would need Cloud Functions (not included).
* XP/levels come only from verified contributions (Новобранец → Изследовател → Откривател → Експерт).

## Privacy and safety
Dangerous or "hide exact location" buildings are stored with coordinates rounded to ~1 km – the exact position is never sent.
The app contains no entry instructions and shows warnings against trespassing.

## Data model (Firestore)
`buildings` (includes photos, `verifiedBy`, `reports`, `history` = historical archive entries, `demolished` flag), `users`, `favorites/{uid}_{buildingId}`, `notifications` (server-written; delivery needs Cloud Functions).

## Project layout
`lib/core` (theme, colors, utils, Firebase config) · `lib/domain` (models, gamification) · `lib/data` (repositories, auth, GPS) · `lib/state` (AppState) · `lib/ui` (screens, widgets).
Re-skin: edit `lib/core/app_colors.dart` only.

## Credits
Map tiles © OpenStreetMap contributors, © CARTO (check their usage terms for production traffic).
