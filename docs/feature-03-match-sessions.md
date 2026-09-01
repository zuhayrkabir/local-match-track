# Feature 03: Match Sessions

This feature prevents every demo run from continuing the same old score. A
referee can create a new match session, switch between sessions, and keep each
match's controls and timeline separate.

## User story

As a referee, I want to create a fresh match before kickoff so that goals,
cards, offsides, halves, and the match clock do not continue from a previous
game.

## Acceptance criteria

- The app shows a synced list of match sessions.
- The referee can create a new match.
- Creating a new match selects it immediately on that device.
- The referee can delete the selected match after confirming.
- Selecting a match changes the visible scoreboard, match controls, clock, and
  timeline to that match.
- Events written in one match do not appear in another match's timeline.
- Deleting a match removes both the match document and its timeline events from
  Ditto.
- Other devices using the same Ditto database can receive the new match session
  through sync.

## Ditto collections

```text
matches
├── demo-match
└── match-<timestamp>-<random>

match_events
├── event for matchId = demo-match
└── event for matchId = match-<timestamp>-<random>
```

The important relationship is `match_events.matchId -> matches._id`.

The app does not create a separate Ditto database per game. It uses one Ditto
database and stores many match documents inside it. That is better for the demo
because multiple devices can discover and sync the same list of matches.

## Manual test checklist

1. Open the app on one device.
2. Tap `Create new match`.
3. Confirm the new match is selected.
4. Start the first half and log a goal.
5. Create another new match.
6. Confirm the score goes back to `0 - 0` and the timeline is empty.
7. Switch back to the previous match.
8. Confirm its score, clock state, and timeline are still there.
9. Delete the selected match and confirm it disappears from the match list.
10. Repeat the same test with two devices running the same Ditto credentials.
