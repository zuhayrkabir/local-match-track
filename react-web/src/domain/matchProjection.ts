import type {
  MatchDocument,
  MatchEventDocument,
  MatchEventType,
  MatchStatus,
  MatchSummary,
  TeamSide,
} from './matchTypes'

export function normalizeMatch(match: MatchDocument): MatchSummary['match'] {
  return {
    ...match,
    _id: String(match._id ?? ''),
    name: match.name?.toString() || 'Untitled match',
    status: match.status ?? 'notStarted',
    selectedHalf: match.selectedHalf ?? 'first',
    elapsedSeconds: readNumber(match.elapsedSeconds),
    createdAtMillis: readNumber(match.createdAtMillis),
    updatedAtMillis: readNumber(match.updatedAtMillis),
  }
}

export function buildSummaries(
  matches: MatchDocument[],
  events: MatchEventDocument[],
): MatchSummary[] {
  const eventsByMatch = new Map<string, MatchEventDocument[]>()

  for (const event of events) {
    const matchId = String(event.matchId ?? '')
    const existing = eventsByMatch.get(matchId) ?? []
    existing.push(event)
    eventsByMatch.set(matchId, existing)
  }

  return matches
    .map((match) => {
      const normalizedMatch = normalizeMatch(match)
      const matchEvents = (eventsByMatch.get(normalizedMatch._id) ?? []).sort(
        (a, b) => readNumber(a.createdAtMillis) - readNumber(b.createdAtMillis),
      )

      return {
        match: normalizedMatch,
        homeScore: scoreFor(matchEvents, 'home'),
        awayScore: scoreFor(matchEvents, 'away'),
        events: matchEvents,
        latestEvent: matchEvents.at(-1),
        statusLabel: statusLabel(normalizedMatch.status),
      }
    })
    .sort(
      (a, b) =>
        readNumber(b.match.updatedAtMillis) - readNumber(a.match.updatedAtMillis),
    )
}

export function eventLabel(type?: MatchEventType): string {
  switch (type) {
    case 'halfStarted':
      return 'Half started'
    case 'halfEnded':
      return 'Half ended'
    case 'goal':
      return 'Goal'
    case 'yellowCard':
      return 'Yellow card'
    case 'redCard':
      return 'Red card'
    case 'offside':
      return 'Offside'
    case 'substitution':
      return 'Substitution'
    case 'foul':
      return 'Foul'
    default:
      return 'Note'
  }
}

export function eventSubject(event: MatchEventDocument): string {
  if (
    event.type === 'substitution' &&
    event.playerName &&
    event.playerNumber &&
    event.substitutePlayerName &&
    event.substitutePlayerNumber
  ) {
    return `${event.teamName ?? 'Team'} #${event.substitutePlayerNumber} ${event.substitutePlayerName} on, #${event.playerNumber} ${event.playerName} off`
  }

  if (event.playerName && event.playerNumber) {
    return `${event.teamName ?? 'Team'} #${event.playerNumber} — ${event.playerName}`
  }

  return event.teamName ?? 'Neutral event'
}

export function minuteLabel(event: MatchEventDocument): string {
  const minute = readNumber(event.minute)
  return minute > 0 ? `${minute}'` : '—'
}

export function clockLabel(match: MatchDocument): string {
  const elapsed = readNumber(match.elapsedSeconds)
  const minutes = Math.floor(elapsed / 60)
  const seconds = elapsed % 60
  return `${minutes.toString().padStart(2, '0')}:${seconds
    .toString()
    .padStart(2, '0')}`
}

function scoreFor(events: MatchEventDocument[], teamSide: TeamSide): number {
  return events.filter(
    (event) => event.type === 'goal' && event.teamSide === teamSide,
  ).length
}

function statusLabel(status?: MatchStatus): string {
  switch (status) {
    case 'firstHalf':
      return 'First half live'
    case 'halftime':
      return 'Halftime'
    case 'secondHalf':
      return 'Second half live'
    case 'fullTime':
      return 'Full time'
    default:
      return 'Not started'
  }
}

function readNumber(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value, 10)
    return Number.isFinite(parsed) ? parsed : 0
  }
  return 0
}
