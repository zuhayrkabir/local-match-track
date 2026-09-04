# Kotlin Android Match Tracker

This folder is a native Android/Kotlin checkpoint for the same local-first soccer app idea as the Flutter demo.

The goal is to learn what Ditto feels like from the Android SDK directly, without disturbing the existing Flutter app.

## What exists right now

- A standalone Android/Kotlin app under `kotlin-android/`.
- A tiny native UI that opens on Android.
- Ditto SDK 5.1.0 installed from Maven Central.
- Ditto initialization through `DittoConfig`.
- Credentials passed at build/run time instead of committed into source.
- A native **Create Kotlin Match** action that writes to the shared `matches` collection.
- A live observed match list using DQL against the local Ditto store.
- Match selection, half selection, start/end half controls, and referee event buttons.
- A live timeline observed from the shared `match_events` collection.
- Dashboard and Match Detail tabs that mirror the Flutter demo structure.
- Match detail sections for match session, referee control, official events, substitutions, rosters, and timeline.
- Confirm-before-write event logging: choose team, choose event type, then tap **Log Event**.
- Match rename and delete controls using the same DQL write/delete patterns as Flutter.
- Role switching between **Referee**, **Assistant Ref**, and **Spectator**.
- Assistant referee proposals written to `match_review_proposals` and accepted/rejected by the referee.
- Ditto Tools Android integrated through **Open Ditto Tools** after Ditto starts.

This app intentionally does not apply the old `org.jetbrains.kotlin.android` Gradle plugin. Android Gradle Plugin 9 has built-in Kotlin support, so applying the old plugin now breaks the build. Ditto Tools uses Jetpack Compose, so this project enables Compose and applies `org.jetbrains.kotlin.plugin.compose`.

## Ditto Tools

Ditto Tools are available from the status card once Ditto is running. Tap **Open Ditto Tools** to launch the native Android tools viewer.

The important architecture detail is that the tools viewer receives the existing app-managed Ditto singleton from `DittoMatchService`. It does not create a second Ditto instance. Creating another instance against the same working directory would trigger Ditto's local file-lock protection.

## Run it on Android

From the repo root:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
ANDROID_HOME="/Users/zuhayrkabir/Library/Android/sdk" \
./android/gradlew -p kotlin-android :app:installDebug \
  -PDITTO_DATABASE_ID="your-database-id" \
  -PDITTO_SERVER_URL="https://your-ditto-server-url" \
  -PDITTO_PLAYGROUND_TOKEN="your-playground-token"
```

Then open **Kotlin Match Tracker** on the Android device.

Do not commit real Ditto tokens. Pass them through `-P...` flags when building.

## Why this is separate from Flutter

The existing app is Flutter-first. Flutter already wraps Android and iOS native projects internally, so mixing a full native Kotlin experiment into `android/` would make the Flutter app harder to reason about.

Keeping this app in `kotlin-android/` gives us a clean learning path:

1. boot a native Kotlin app;
2. initialize Ditto;
3. add DQL writes and observers;
4. add match dashboard UI;
5. add match event logging;
6. add assistant referee proposals;
7. compare native Android patterns against the Flutter + Riverpod version.

## Current shared Ditto collections

This Kotlin app uses the same collection names as the Flutter app:

- `matches`
- `match_events`
- `match_review_proposals`
- `match_participants`

That means matches and referee events created here can appear in Flutter clients when both apps use the same Ditto database credentials.
