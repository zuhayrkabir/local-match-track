# Local-First Match Tracker

A small Flutter app for learning Ditto SDK 5.1 through a soccer match-tracking use case.

The point of this repo is not to build the entire finished soccer product immediately. This is the Sprint Zero baseline:

```text
Flutter app starts
→ Ditto 5.1 opens
→ app subscribes to match_events
→ user can insert a test goal
→ local observer updates the timeline
```

## Why this exists

This project is a learning/demo app for Ditto:

- local-first writes
- DQL reads/writes
- sync subscriptions
- peer presence
- offline/reconnect behavior on real devices

## Current stack

- Flutter
- Dart
- Ditto Flutter SDK 5.1.0
- Riverpod

## Temporary Android build note

This repo currently points `ditto_live` at `vendor/ditto_live`, a local copy of the Ditto Flutter SDK 5.1.0 package.

Why: the published Flutter package's Android plugin config compiled its library subproject against Android SDK 34, while its Ditto Android 5.1.0 artifacts require SDK 36+. The local copy changes the plugin Android `compileSdk`/`targetSdk` to 37 so the prototype can build against the Android SDK installed on this machine.

If a newer Ditto Flutter package fixes this upstream, remove the local path dependency and return to:

```yaml
ditto_live: 5.1.0
```

## Current feature

See [Feature 01: Log Match Event](docs/feature-01-log-match-event.md).

## Run it

```bash
flutter pub get
flutter run
```

If you run without any Ditto activation values, the app will render but syncing/data writes will be disabled. That is expected: Ditto still needs either an offline license token for Small Peers Only mode or server/playground credentials for server mode.

For a Ditto Server / Playground run, pass credentials with `--dart-define` values instead of committing them:

```bash
flutter run \
  --dart-define=DITTO_DATABASE_ID=your-database-id \
  --dart-define=DITTO_SERVER_URL=https://your-server-url \
  --dart-define=DITTO_PLAYGROUND_TOKEN=your-development-token
```

For local small-peers-only testing, the app uses a fixed demo database ID by default:

```text
11111111-1111-4111-8111-111111111111
```

If your Ditto setup requires an offline-only license token, pass it like this:

```bash
flutter run \
  --dart-define=DITTO_DATABASE_ID=11111111-1111-4111-8111-111111111111 \
  --dart-define=DITTO_OFFLINE_LICENSE_TOKEN=your-offline-license-token
```

## Architecture note

Keep these responsibilities separate:

- `DittoManager` configures and owns the Ditto SDK instance.
- Repositories read/write soccer data using the configured Ditto instance.
- Features/screens represent user-facing use cases.
- Ditto owns the local store, sync engine, CRDT behavior, and presence graph.

In one sentence:

```text
DittoManager configures Ditto; repositories use Ditto; screens use repositories.
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
