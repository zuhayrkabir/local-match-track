# Feature 04: Roles, Rosters, and Substitutions

This feature makes the demo closer to a real match workflow without changing
the core Ditto architecture.

## User stories

- As a user, I choose whether this device is acting as a referee or spectator
  when the app opens.
- As a spectator, I can only view the synced match score, clock, session list,
  roster, and timeline.
- As a referee, I can control the match and log official events.
- As a referee, I can log a substitution by choosing the team, the player going
  off, and the bench player coming on.

## Current permission boundary

Permissions are enforced in the Flutter UI for this prototype:

- Referee devices show write controls.
- Spectator devices hide write controls.

The role choice itself is local to the device right now. Match sessions, match
state, and match events still sync through Ditto.

## Roster assumptions

Each demo team has 18 players:

- 11 starters
- 7 bench players

This gives the substitution workflow enough structure without requiring a full
team-management feature yet.

## Ditto data impact

Substitutions are still stored as `match_events` documents:

```text
match_events/event-...
├── type: substitution
├── teamSide
├── playerId / playerName / playerNumber
└── substitutePlayerId / substitutePlayerName / substitutePlayerNumber
```

That means substitutions sync exactly like goals, cards, and offsides.
