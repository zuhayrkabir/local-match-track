# Feature 01: Log Match Event

## Goal

Let a referee or coach record one thing that happened during a match. The first implementation is deliberately tiny: a button creates a test `goal` event and displays it in a timeline.

This is the first Ditto learning feature because it exercises the core loop:

```text
user action → local Ditto write → local observer update → sync subscription can replicate it
```

## Personas

| Persona | Why they use it |
| --- | --- |
| Main referee | Records official match events. |
| Assistant referee | Records observations that may need review later. |
| Coach / stat keeper | Records play-by-play for team awareness. |

## Inputs

For the Sprint Zero version:

| Input | Current value |
| --- | --- |
| Event type | `goal` |
| Team | `Green FC` |
| Minute | Current clock minute from the device |
| Match ID | `demo-match` |

Later this becomes real UI:

| Input | Future source |
| --- | --- |
| Event type | User selects goal/card/foul/substitution/note |
| Team | User selects from match teams |
| Player | User selects from roster |
| Minute | Match clock |
| Created by | Device/user role |

## Output

A document is inserted into the `match_events` collection:

```json
{
  "_id": "event-...",
  "matchId": "demo-match",
  "type": "goal",
  "teamName": "Green FC",
  "minute": 34,
  "createdAtMillis": 1787930000000
}
```

## Ditto SDK concepts used

| SDK concept | Why it matters |
| --- | --- |
| `DittoConfig` | Configures the database ID and connection mode. |
| `Ditto.open(config)` | Opens the local Ditto instance. |
| `ditto.sync.registerSubscription(...)` | Declares which synced documents this peer wants. |
| `ditto.sync.start()` | Starts Ditto networking/transports. |
| `ditto.store.execute(...)` | Runs DQL statements for reads/writes. |
| `store.registerObserver(...)` | Reacts when local query results change. |
| `ditto.presence.observe(...)` | Reports available peers/connections for observability. |

## Dependencies before this feature becomes real

- Match setup: need a real match ID.
- Team setup: need selectable teams.
- Roster setup: need selectable players.
- Role setup: need to know whether the device is main ref, assistant ref, or coach.

## Test cases

- App starts and opens Ditto without crashing.
- User taps `Add test goal`.
- A new event appears in the local timeline.
- Restarting the app still shows persisted local events.
- Two devices using the same database ID and compatible Ditto config eventually show the same event list.
