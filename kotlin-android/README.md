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

This app intentionally does not apply the old `org.jetbrains.kotlin.android` Gradle plugin. Android Gradle Plugin 9 has built-in Kotlin support, so applying the old plugin now breaks the build.

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
6. compare native Android patterns against the Flutter + Riverpod version.
