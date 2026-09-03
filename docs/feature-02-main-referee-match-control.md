# Feature 02: Main Referee Match Control

This feature is the first real referee workflow. The main referee can choose a
half, start it, end it, and log official events for a selected player.

## Persona

- Main referee: owns match control and can write official match state.
- Assistant referee: future persona with fewer permissions.
- Coach/viewer: future persona that can observe the synced timeline and score.

## Inputs

- Selected half: first half or second half.
- Control action: start half or end half.
- Official event type: goal, yellow card, red card, or offside.
- Team: selected before choosing the player involved.
- Player: selected from the chosen team's demo roster.

## Outputs

- A synced `matches` document for match control state.
- A synced `match_events` play-by-play log.
- A score derived from synced goal events.
- A match clock derived from synced start/end state instead of the wall-clock
  minute.
- A timeline that updates on other devices through Ditto observers.

## Ditto collections

```text
matches
└── demo-match
    ├── selectedHalf
    ├── status
    ├── elapsedSeconds
    ├── clockStartedAtMillis
    └── updatedAtMillis

match_events
└── event-<timestamp>-<random>
    ├── matchId
    ├── type
    ├── teamName
    ├── player fields, when applicable
    ├── minute
    └── createdAtMillis
```

`matches` is the small piece of shared match state. `match_events` is the
append-style event log. This separation matters because two referees adding
different events should not fight over one big document.

## Test cases

- App starts with first half selected and status set to not started.
- Selecting the second half changes the synced match-control document.
- Starting the selected half writes match state and a half-started timeline
  event.
- The visible timer advances while the half is live.
- Ending the current half writes match state and a half-ended timeline event.
- Goals, cards, and offsides are tied to a selected team and player.
- Older synced events without player fields still render safely.

## Multi-device demo checklist

1. Launch the app on two Android devices with the same Ditto database ID and
   token.
2. On Device A, select `First half`, then tap `Start First half`.
3. Confirm Device B changes to `First half live` and shows a `Half started`
   event. Confirm the timer is advancing on both devices.
4. On Device A, choose `Goal`, choose `Green FC`, then log the event for
   `Green FC #7`.
5. Confirm Device B shows the new timeline event and the score changes.
6. Put one device into airplane mode, log another event, then reconnect.
7. Confirm both devices converge to the same timeline.
