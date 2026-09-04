# Swift iOS Match Tracker

This folder is the native Swift/iOS checkpoint for the same local-first soccer app idea as the Flutter and Kotlin demos.

The purpose is to learn Ditto from the Swift SDK directly while keeping the monorepo structure clean:

- Flutter app at the repo root
- Kotlin Android app in `kotlin-android/`
- Swift iOS app in `swift-ios/`

## What exists right now

- A standalone SwiftUI iOS app.
- Ditto Swift SDK dependency through Swift Package Manager.
- Ditto initialization through `DittoConfig`.
- Native Ditto Tools integration through `DittoSwiftTools` / `DittoAllToolsMenu`.
- Development credentials generated into `Env.swift` from the repo-level `.env`.
- DQL strict mode disabled for schema-free v5 documents.
- Sync subscriptions for the same shared collections as Flutter/Kotlin:
  - `matches`
  - `match_events`
  - `match_review_proposals`
  - `match_participants`
- Store observers for `matches` and `match_events`.
- A Dashboard page for Ditto status, role selection, featured match, and all synced matches.
- A Match Detail page for the selected match, match session state, referee controls, rename/delete, and the event timeline.
- Referee mode can create matches, rename matches, start/end halves, delete matches, review assistant proposals, and log official events/substitutions.
- Assistant Ref mode can propose foul/offside reviews only when a fresh referee participant heartbeat is visible for the selected match.
- Spectator mode is read-only and watches synced match state, score, clock, and timeline updates.
- Sample rosters include 18 starters and 7 bench players per team for player-specific event logging.
- A SwiftUI live clock powered by `TimelineView`.

## Cross-device role workflow

The Swift checkpoint now uses two Ditto collections to model live collaboration:

- `match_participants` stores lightweight participant heartbeat documents. The app
  updates the local participant document every few seconds with role, platform,
  display name, selected match, and `lastSeenMillis`.
- `match_review_proposals` stores assistant referee proposals. Assistants can
  submit foul/offside proposals when a fresh referee heartbeat is present. Referees
  can accept or reject pending proposals from the Match Detail screen. Accepted
  proposals become official `match_events`.

This keeps authorization simple for the demo: the UI gates role actions, while
Ditto sync distributes the underlying state across nearby devices and the server.

## Ditto Tools

The Swift app imports `DittoAllToolsMenu` from the public `DittoSwiftTools`
package. When Ditto is running, tap **Tools** or **Open Ditto Tools** to inspect
native Ditto diagnostics from inside the app.

This is intentionally different from the Flutter checkpoint: the Swift tools
package includes native tools such as the all-tools menu and presence viewer, so
the iOS app can demonstrate deeper SDK observability.

## Configure credentials

Create a repo-level `.env` file:

```bash
cp swift-ios/.env.sample .env
```

Then fill in:

```bash
DITTO_DATABASE_ID="your-database-id"
DITTO_SERVER_URL="https://your-ditto-server-url"
DITTO_PLAYGROUND_TOKEN="your-development-token"
```

Do not commit `.env` or generated `Env.swift`.

## Run in Xcode

Open:

```bash
open swift-ios/SwiftMatchTracker.xcodeproj
```

Then:

1. Select the `SwiftMatchTracker` project.
2. Select the `SwiftMatchTracker` target.
3. Go to **Signing & Capabilities**.
4. Pick your Apple development team.
5. Change the bundle identifier if needed.
6. Select an iPhone or iOS simulator.
7. Run.

## Why this app uses the same collections

The value of this demo is cross-SDK sync. A match created in Swift should sync to Flutter/Kotlin clients when all devices use the same Ditto database credentials and subscriptions.

The Swift app currently focuses on the first useful checkpoint: prove that the Swift SDK can join the same data model and write/read the same match state.
