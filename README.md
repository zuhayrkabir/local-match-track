# Local-First Match Tracker

Local-First Match Tracker is a multi-platform Ditto SDK demo for a soccer match-tracking workflow. The project is organized as a monorepo so each client can show the same local-first data model through a different SDK or platform.

The app idea is intentionally concrete: referees, assistant referees, spectators, and dashboard viewers can participate in the same match from separate devices. Each client writes to its local Ditto store first, then Ditto syncs those documents across nearby peers and/or Ditto Server when connectivity is available.

## Monorepo layout

| Path | Platform | Purpose |
| --- | --- | --- |
| `flutter/` | Flutter Android, iOS, and Web | Primary/reference implementation with the most complete UI and demo workflow. |
| `kotlin-android/` | Native Android/Kotlin | Native Android checkpoint using the Kotlin SDK and Android Ditto Tools. |
| `swift-ios/` | Native iOS/SwiftUI | Native iOS checkpoint using DittoSwift and DittoSwiftTools. |
| `react-web/` | React Web | Browser dashboard checkpoint. Currently scaffolded with shared projection logic and sample data while the browser auth strategy is decided. |
| `docs/` | Shared docs | Feature notes, architecture notes, and progress tracking from the original Flutter build. |

## Shared Ditto data model

All platform clients are intended to use the same Ditto database and the same collection names:

- `matches`
- `match_events`
- `match_review_proposals`
- `match_participants`

The common sync flow is:

```text
user action
→ platform UI/repository writes to local Ditto store
→ local observer updates that device immediately
→ Ditto sync replicates documents to other peers/server
→ other devices observe their local store changes
→ their UI updates
```

## Current platform status

| Platform | Status |
| --- | --- |
| Flutter | Most complete implementation: dashboard, match detail, role workflows, assistant proposals, substitutions, rosters, web dashboard, and Flutter Ditto Tools entry point. |
| Kotlin Android | Functional native Android implementation with dashboard/detail views, referee workflow, assistant proposals, spectator restrictions, timer, and Android Ditto Tools. |
| Swift iOS | Functional native iOS implementation with dashboard/detail views, referee workflow, assistant proposals, participant heartbeat, substitutions, rosters, and native Ditto Tools. |
| React Web | Initial safe scaffold: Vite + React + TypeScript dashboard UI and shared match projection over sample data. Real Ditto Web reads are deferred until browser auth/token exposure is explicitly decided. |

## Credentials

Do not commit credentials. Use local environment/configuration values when running each platform.

The common values are:

```text
DITTO_DATABASE_ID
DITTO_SERVER_URL
DITTO_PLAYGROUND_TOKEN
```

Swift reads these from a repo-level `.env` file generated from `swift-ios/.env.sample`. Flutter receives them through `--dart-define`. Kotlin receives them through Gradle `-P...` properties.

React Web currently does not consume credentials. Browser JavaScript is inspectable, so directly bundling `DITTO_PLAYGROUND_TOKEN` would expose the token to anyone who can load the web app. Choose a demo-only direct-token approach or a safer token-exchange/proxy approach before wiring React to Ditto Server.

## Run Flutter

```bash
cd flutter
flutter pub get
flutter devices
flutter run -d your-device-id \
  --dart-define=DITTO_DATABASE_ID=your-database-id \
  --dart-define=DITTO_SERVER_URL=https://your-ditto-server-url \
  --dart-define=DITTO_PLAYGROUND_TOKEN=your-development-token
```

Run the Flutter web dashboard:

```bash
cd flutter
flutter run -d chrome \
  --web-hostname=localhost \
  --web-port=8080 \
  --dart-define=DITTO_DATABASE_ID=your-database-id \
  --dart-define=DITTO_SERVER_URL=https://your-ditto-server-url \
  --dart-define=DITTO_PLAYGROUND_TOKEN=your-development-token
```

## Run Kotlin Android

From the repo root:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
ANDROID_HOME="/Users/zuhayrkabir/Library/Android/sdk" \
./flutter/android/gradlew -p kotlin-android :app:installDebug \
  -PDITTO_DATABASE_ID="your-database-id" \
  -PDITTO_SERVER_URL="https://your-ditto-server-url" \
  -PDITTO_PLAYGROUND_TOKEN="your-playground-token"
```

Note: this command uses the local Flutter Android Gradle wrapper that exists on the development machine. If this repo is prepared for a public/example-app release, add a dedicated root Gradle wrapper or Kotlin-specific wrapper.

## Run Swift iOS

From the repo root:

```bash
cp swift-ios/.env.sample .env
open -e .env
open swift-ios/SwiftMatchTracker.xcodeproj
```

Fill in `.env`, then run the `SwiftMatchTracker` scheme from Xcode on a simulator or iPhone. For a compile-only check without device signing, build the arm64 iOS Simulator target:

```bash
xcodebuild -project swift-ios/SwiftMatchTracker.xcodeproj \
  -scheme SwiftMatchTracker \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  build
```

## Run React Web

```bash
cd react-web
npm install
npm run dev
```

This first checkpoint uses sample data only. It proves the React dashboard shell
and shared match projection without risking browser-side credential exposure.

## Validation without physical devices

When physical devices are unavailable, avoid making risky feature changes that require mesh validation. Prefer:

- `flutter analyze` and `flutter test` from `flutter/`
- `flutter build web` from `flutter/`
- Kotlin `assembleDebug`
- Swift `xcodebuild` compile checks
- React `npm run typecheck` and `npm run build` from `react-web/`
- documentation, repo structure, and data-model cleanup

Physical devices are still required before claiming Bluetooth, LAN, peer-to-peer, or multi-device sync behavior.

## Known limitations

- React Web is scaffolded but does not read from Ditto yet; browser-safe authentication still needs to be chosen.
- Flutter remains the hero UI; Kotlin and Swift are native SDK checkpoints with similar workflows but less visual polish.
- Assistant/referee role authorization is demo-level UI logic, not hardened production auth.
- Duplicate event detection and conflict test harnesses are not implemented yet.
- Formal latency metrics require a dedicated instrumentation pass and physical-device testing.
