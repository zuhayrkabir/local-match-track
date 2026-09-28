import type { MatchDocument, MatchEventDocument } from './domain/matchTypes'

export const sampleMatches: MatchDocument[] = [
  {
    _id: 'sample-final',
    name: 'Demo Final',
    selectedHalf: 'second',
    status: 'secondHalf',
    createdAtMillis: 1,
    updatedAtMillis: 4,
    elapsedSeconds: 63 * 60 + 12,
  },
  {
    _id: 'sample-field-two',
    name: 'Field Two',
    selectedHalf: 'first',
    status: 'halftime',
    createdAtMillis: 2,
    updatedAtMillis: 3,
    elapsedSeconds: 45 * 60,
  },
]

export const sampleEvents: MatchEventDocument[] = [
  {
    _id: 'sample-event-1',
    matchId: 'sample-final',
    type: 'halfStarted',
    teamName: 'Neutral',
    minute: 46,
    createdAtMillis: 1,
  },
  {
    _id: 'sample-event-2',
    matchId: 'sample-final',
    type: 'goal',
    teamName: 'Green FC',
    teamSide: 'home',
    playerName: 'Ari Khan',
    playerNumber: 9,
    minute: 52,
    createdAtMillis: 2,
  },
  {
    _id: 'sample-event-3',
    matchId: 'sample-final',
    type: 'yellowCard',
    teamName: 'White FC',
    teamSide: 'away',
    playerName: 'Noah Reed',
    playerNumber: 6,
    minute: 59,
    createdAtMillis: 3,
  },
  {
    _id: 'sample-event-4',
    matchId: 'sample-final',
    type: 'foul',
    teamName: 'Green FC',
    teamSide: 'home',
    playerName: 'Leo Park',
    playerNumber: 4,
    minute: 62,
    createdAtMillis: 4,
  },
]
