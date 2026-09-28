export type MatchStatus =
  | 'notStarted'
  | 'firstHalf'
  | 'halftime'
  | 'secondHalf'
  | 'fullTime'

export type MatchHalf = 'first' | 'second'

export type TeamSide = 'home' | 'away'

export type MatchEventType =
  | 'halfStarted'
  | 'halfEnded'
  | 'goal'
  | 'yellowCard'
  | 'redCard'
  | 'offside'
  | 'substitution'
  | 'foul'
  | 'note'

export type MatchDocument = {
  _id: string
  name?: string
  selectedHalf?: MatchHalf
  status?: MatchStatus
  createdAtMillis?: number
  updatedAtMillis?: number
  elapsedSeconds?: number
  clockStartedAtMillis?: number
}

export type MatchEventDocument = {
  _id: string
  matchId: string
  type?: MatchEventType
  teamName?: string
  minute?: number
  createdAtMillis?: number
  playerId?: string
  playerName?: string
  playerNumber?: number
  substitutePlayerId?: string
  substitutePlayerName?: string
  substitutePlayerNumber?: number
  teamSide?: TeamSide
}

export type MatchSummary = {
  match: Required<
    Pick<
      MatchDocument,
      '_id' | 'name' | 'status' | 'selectedHalf' | 'elapsedSeconds'
    >
  > &
    MatchDocument
  homeScore: number
  awayScore: number
  events: MatchEventDocument[]
  latestEvent?: MatchEventDocument
  statusLabel: string
}
