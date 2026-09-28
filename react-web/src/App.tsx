import { useMemo, useState } from 'react'
import {
  DittoProvider,
  useDitto,
  useQuery,
  useRemotePeers,
} from '@dittolive/react-ditto'
import {
  buildSummaries,
  clockLabel,
  eventLabel,
  eventSubject,
  minuteLabel,
} from './domain/matchProjection'
import type {
  MatchDocument,
  MatchEventType,
  MatchEventDocument,
  MatchHalf,
  MatchStatus,
  MatchSummary,
  TeamSide,
} from './domain/matchTypes'
import { sampleEvents, sampleMatches } from './sampleData'
import { createDemoDitto } from './services/createDemoDitto'

type AppMode = 'sample' | 'ditto'
type LoggableEventType = Extract<
  MatchEventType,
  'goal' | 'foul' | 'yellowCard' | 'redCard' | 'offside'
>

type MatchEventInput = {
  matchId: string
  type: LoggableEventType
  teamSide: TeamSide
  minute: number
}

type MatchSessionInput = {
  matchId: string
  half: MatchHalf
  elapsedSeconds: number
  action: 'start' | 'end'
}

export default function App() {
  const [mode, setMode] = useState<AppMode>('sample')

  return (
    <main className="app-shell">
      <AppHeader mode={mode} onModeChange={setMode} />

      {mode === 'ditto' ? (
        <DittoProvider setup={createDemoDitto}>
          {({ loading, error }) => {
            if (loading) {
              return (
                <StatusCard
                  eyebrow="Ditto Web"
                  title="Opening browser peer…"
                  copy="React is opening a Ditto Web instance, authenticating to the demo Ditto Server, and preparing read-only queries."
                />
              )
            }

            if (error) {
              return (
                <StatusCard
                  eyebrow="Ditto setup failed"
                  title="Could not connect React Web to Ditto."
                  copy={String(error)}
                  tone="error"
                />
              )
            }

            return <ConnectedDashboard />
          }}
        </DittoProvider>
      ) : (
        <SampleDashboard />
      )}
    </main>
  )
}

function AppHeader({
  mode,
  onModeChange,
}: {
  mode: AppMode
  onModeChange: (mode: AppMode) => void
}) {
  return (
    <>
      <header className="hero">
        <div>
          <p className="eyebrow">React Web checkpoint</p>
          <h1>Local-First Match Center</h1>
          <p>
            Browser dashboard for the same soccer match data model used by
            Flutter, Kotlin, and Swift.
          </p>
        </div>
        <div className="sync-card">
          <span>Mode</span>
          <strong>{mode === 'sample' ? 'Safe' : 'Demo'}</strong>
          <small>
            {mode === 'sample'
              ? 'sample data only'
              : 'Ditto Server read-only'}
          </small>
        </div>
      </header>

      <section className="notice-card">
        <div>
          <p className="eyebrow">Connection mode</p>
          <p>
            Sample mode never opens Ditto. Demo Ditto mode reads real synced
            data, but browser JavaScript can expose demo tokens, so only use a
            disposable development token.
          </p>
        </div>
        <div className="mode-actions">
          <button
            className={mode === 'sample' ? 'mode-button active' : 'mode-button'}
            onClick={() => onModeChange('sample')}
            type="button"
          >
            Sample data
          </button>
          <button
            className={mode === 'ditto' ? 'mode-button active' : 'mode-button'}
            onClick={() => onModeChange('ditto')}
            type="button"
          >
            Demo Ditto Server
          </button>
        </div>
      </section>
    </>
  )
}

function SampleDashboard() {
  const summaries = useMemo(
    () => buildSummaries(sampleMatches, sampleEvents),
    [],
  )

  return <Dashboard summaries={summaries} peerCount={0} sourceLabel="Sample" />
}

function ConnectedDashboard() {
  const matchesQuery = useQuery<MatchDocument>('SELECT * FROM matches')
  const eventsQuery = useQuery<MatchEventDocument>('SELECT * FROM match_events')
  const { remotePeers } = useRemotePeers()

  const summaries = useMemo(
    () =>
      buildSummaries(
        matchesQuery.items.map((item) => item.value),
        eventsQuery.items.map((item) => item.value),
      ),
    [matchesQuery.items, eventsQuery.items],
  )

  const error = matchesQuery.error ?? eventsQuery.error

  return (
    <>
      {error && (
        <StatusCard
          eyebrow="Query error"
          title="Ditto query failed."
          copy={String(error)}
          tone="error"
        />
      )}
      <DittoBackedDashboard
        isLoading={matchesQuery.isLoading || eventsQuery.isLoading}
        peerCount={remotePeers.length}
        summaries={summaries}
      />
    </>
  )
}

function DittoBackedDashboard({
  summaries,
  peerCount,
  isLoading,
}: {
  summaries: MatchSummary[]
  peerCount: number
  isLoading: boolean
}) {
  const { ditto } = useDitto(null)
  const [writeStatus, setWriteStatus] = useState<string>()
  const [writeError, setWriteError] = useState<string>()

  async function createMatch(name: string) {
    if (!ditto) return

    setWriteStatus('Creating match…')
    setWriteError(undefined)

    try {
      const now = Date.now()
      const doc: MatchDocument = {
        _id: crypto.randomUUID(),
        name,
        status: 'notStarted',
        selectedHalf: 'first',
        elapsedSeconds: 0,
        createdAtMillis: now,
        updatedAtMillis: now,
      }

      await ditto.store.execute(
        'INSERT INTO matches DOCUMENTS (:doc) ON ID CONFLICT DO UPDATE',
        { doc },
      )
      setWriteStatus(`Created ${name}.`)
    } catch (error) {
      setWriteStatus(undefined)
      setWriteError(String(error))
    }
  }

  async function renameMatch(matchId: string, name: string) {
    if (!ditto) return

    setWriteStatus('Renaming match…')
    setWriteError(undefined)

    try {
      await ditto.store.execute(
        'UPDATE matches SET name = :name, updatedAtMillis = :updatedAtMillis WHERE _id = :matchId',
        { matchId, name, updatedAtMillis: Date.now() },
      )
      setWriteStatus(`Renamed match to ${name}.`)
    } catch (error) {
      setWriteStatus(undefined)
      setWriteError(String(error))
    }
  }

  async function logMatchEvent(input: MatchEventInput) {
    if (!ditto) return

    setWriteStatus(`Logging ${eventLabel(input.type).toLowerCase()}…`)
    setWriteError(undefined)

    try {
      const now = Date.now()
      const event: MatchEventDocument = {
        _id: crypto.randomUUID(),
        matchId: input.matchId,
        type: input.type,
        teamSide: input.teamSide,
        teamName: input.teamSide === 'home' ? 'Home' : 'Away',
        minute: input.minute,
        createdAtMillis: now,
      }

      await ditto.store.execute(
        'INSERT INTO match_events DOCUMENTS (:event) ON ID CONFLICT DO UPDATE',
        { event },
      )
      await ditto.store.execute(
        'UPDATE matches SET updatedAtMillis = :updatedAtMillis WHERE _id = :matchId',
        { matchId: input.matchId, updatedAtMillis: now },
      )
      setWriteStatus(`Logged ${eventLabel(input.type).toLowerCase()}.`)
    } catch (error) {
      setWriteStatus(undefined)
      setWriteError(String(error))
    }
  }

  async function updateMatchSession(input: MatchSessionInput) {
    if (!ditto) return

    const isStart = input.action === 'start'
    const halfLabel = input.half === 'first' ? 'first half' : 'second half'

    setWriteStatus(`${isStart ? 'Starting' : 'Ending'} ${halfLabel}…`)
    setWriteError(undefined)

    try {
      const now = Date.now()
      const nextStatus = nextMatchStatus(input.action, input.half)

      await ditto.store.execute(
        [
          'UPDATE matches',
          'SET status = :status,',
          'selectedHalf = :selectedHalf,',
          'elapsedSeconds = :elapsedSeconds,',
          'clockStartedAtMillis = :clockStartedAtMillis,',
          'updatedAtMillis = :updatedAtMillis',
          'WHERE _id = :matchId',
        ].join(' '),
        {
          matchId: input.matchId,
          status: nextStatus,
          selectedHalf: input.half,
          elapsedSeconds: input.elapsedSeconds,
          clockStartedAtMillis: isStart ? now : 0,
          updatedAtMillis: now,
        },
      )

      const event: MatchEventDocument = {
        _id: crypto.randomUUID(),
        matchId: input.matchId,
        type: isStart ? 'halfStarted' : 'halfEnded',
        teamName: halfLabel,
        minute: Math.max(0, Math.floor(input.elapsedSeconds / 60)),
        createdAtMillis: now,
      }

      await ditto.store.execute(
        'INSERT INTO match_events DOCUMENTS (:event) ON ID CONFLICT DO UPDATE',
        { event },
      )
      setWriteStatus(`${isStart ? 'Started' : 'Ended'} ${halfLabel}.`)
    } catch (error) {
      setWriteStatus(undefined)
      setWriteError(String(error))
    }
  }

  return (
    <Dashboard
      canWrite
      onCreateMatch={createMatch}
      onLogMatchEvent={logMatchEvent}
      onRenameMatch={renameMatch}
      onUpdateMatchSession={updateMatchSession}
      peerCount={peerCount}
      sourceLabel={isLoading ? 'Loading' : 'Ditto'}
      summaries={summaries}
      writeError={writeError}
      writeStatus={writeStatus}
    />
  )
}

function Dashboard({
  summaries,
  peerCount,
  sourceLabel,
  canWrite = false,
  onCreateMatch,
  onLogMatchEvent,
  onRenameMatch,
  onUpdateMatchSession,
  writeStatus,
  writeError,
}: {
  summaries: MatchSummary[]
  peerCount: number
  sourceLabel: string
  canWrite?: boolean
  onCreateMatch?: (name: string) => Promise<void>
  onLogMatchEvent?: (input: MatchEventInput) => Promise<void>
  onRenameMatch?: (matchId: string, name: string) => Promise<void>
  onUpdateMatchSession?: (input: MatchSessionInput) => Promise<void>
  writeStatus?: string
  writeError?: string
}) {
  const [selectedMatchId, setSelectedMatchId] = useState<string | undefined>()
  const selectedMatch =
    summaries.find((summary) => summary.match._id === selectedMatchId) ??
    summaries[0]

  return (
    <>
      <section className="data-source-card">
        <span>{sourceLabel} source</span>
        <strong>{summaries.length}</strong>
        <span>matches · {peerCount} remote peers</span>
      </section>
      <MatchOperations
        canWrite={canWrite}
        onCreateMatch={onCreateMatch}
        onLogMatchEvent={onLogMatchEvent}
        onRenameMatch={onRenameMatch}
        onUpdateMatchSession={onUpdateMatchSession}
        selectedMatch={selectedMatch}
        writeError={writeError}
        writeStatus={writeStatus}
      />
      <section className="dashboard-grid">
        <FeaturedMatch summary={selectedMatch} />
        <MatchGrid
          summaries={summaries}
          selectedMatchId={selectedMatch?.match._id}
          onSelect={setSelectedMatchId}
        />
      </section>

      <Timeline summary={selectedMatch} />
    </>
  )
}

function MatchOperations({
  canWrite,
  selectedMatch,
  onCreateMatch,
  onLogMatchEvent,
  onRenameMatch,
  onUpdateMatchSession,
  writeStatus,
  writeError,
}: {
  canWrite: boolean
  selectedMatch?: MatchSummary
  onCreateMatch?: (name: string) => Promise<void>
  onLogMatchEvent?: (input: MatchEventInput) => Promise<void>
  onRenameMatch?: (matchId: string, name: string) => Promise<void>
  onUpdateMatchSession?: (input: MatchSessionInput) => Promise<void>
  writeStatus?: string
  writeError?: string
}) {
  const [newMatchName, setNewMatchName] = useState('')
  const [renameValue, setRenameValue] = useState('')
  const [eventType, setEventType] = useState<LoggableEventType>('goal')
  const [teamSide, setTeamSide] = useState<TeamSide>('home')
  const [eventMinute, setEventMinute] = useState('')
  const [isSaving, setIsSaving] = useState(false)

  const currentName = selectedMatch?.match.name ?? ''
  const renameDraft = renameValue || currentName

  async function handleCreate() {
    const trimmedName =
      newMatchName.trim() ||
      `React Web Match ${new Date().toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit',
      })}`

    if (!onCreateMatch) return
    setIsSaving(true)
    try {
      await onCreateMatch(trimmedName)
      setNewMatchName('')
    } finally {
      setIsSaving(false)
    }
  }

  async function handleRename() {
    const trimmedName = renameDraft.trim()
    if (!selectedMatch || !onRenameMatch || !trimmedName) return

    setIsSaving(true)
    try {
      await onRenameMatch(selectedMatch.match._id, trimmedName)
      setRenameValue('')
    } finally {
      setIsSaving(false)
    }
  }

  async function handleLogEvent() {
    if (!selectedMatch || !onLogMatchEvent) return

    const parsedMinute = Number.parseInt(eventMinute, 10)
    const minute = Number.isFinite(parsedMinute)
      ? Math.max(0, Math.min(parsedMinute, 130))
      : Math.max(0, Math.floor(selectedMatch.match.elapsedSeconds / 60))

    setIsSaving(true)
    try {
      await onLogMatchEvent({
        matchId: selectedMatch.match._id,
        type: eventType,
        teamSide,
        minute,
      })
      setEventMinute('')
    } finally {
      setIsSaving(false)
    }
  }

  async function handleSessionAction(action: MatchSessionInput['action']) {
    if (!selectedMatch || !onUpdateMatchSession) return

    setIsSaving(true)
    try {
      await onUpdateMatchSession({
        action,
        elapsedSeconds: selectedMatch.match.elapsedSeconds,
        half: selectedMatch.match.selectedHalf,
        matchId: selectedMatch.match._id,
      })
    } finally {
      setIsSaving(false)
    }
  }

  async function handleStartHalf(half: MatchHalf) {
    if (!selectedMatch || !onUpdateMatchSession) return

    setIsSaving(true)
    try {
      await onUpdateMatchSession({
        action: 'start',
        elapsedSeconds: half === 'first' ? 0 : 45 * 60,
        half,
        matchId: selectedMatch.match._id,
      })
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <section className="operations-card">
      <div>
        <p className="eyebrow">Match operations</p>
        <h2>Demo writes</h2>
        <p>
          Create or rename matches from the browser. These writes go into the
          local Ditto Web store first, then sync through Ditto Server to the
          mobile apps.
        </p>
      </div>

      <div className="operation-grid">
        <label>
          <span>New match</span>
          <input
            disabled={!canWrite || isSaving}
            onChange={(event) => setNewMatchName(event.target.value)}
            placeholder="Saturday Final"
            value={newMatchName}
          />
          <button disabled={!canWrite || isSaving} onClick={handleCreate}>
            Create match
          </button>
        </label>

        <label>
          <span>Selected match name</span>
          <input
            disabled={!canWrite || isSaving || !selectedMatch}
            onChange={(event) => setRenameValue(event.target.value)}
            placeholder={currentName || 'Select a match'}
            value={renameValue}
          />
          <button
            disabled={!canWrite || isSaving || !selectedMatch}
            onClick={handleRename}
          >
            Rename selected
          </button>
        </label>
      </div>

      <div className="event-logger">
        <div>
          <p className="eyebrow">Official event</p>
          <h3>Log selected match event</h3>
        </div>
        <div className="event-logger-grid">
          <label>
            <span>Event</span>
            <select
              disabled={!canWrite || isSaving || !selectedMatch}
              onChange={(event) =>
                setEventType(event.target.value as LoggableEventType)
              }
              value={eventType}
            >
              <option value="goal">Goal</option>
              <option value="foul">Foul</option>
              <option value="yellowCard">Yellow card</option>
              <option value="redCard">Red card</option>
              <option value="offside">Offside</option>
            </select>
          </label>

          <label>
            <span>Team</span>
            <select
              disabled={!canWrite || isSaving || !selectedMatch}
              onChange={(event) => setTeamSide(event.target.value as TeamSide)}
              value={teamSide}
            >
              <option value="home">Home</option>
              <option value="away">Away</option>
            </select>
          </label>

          <label>
            <span>Minute</span>
            <input
              disabled={!canWrite || isSaving || !selectedMatch}
              inputMode="numeric"
              max="130"
              min="0"
              onChange={(event) => setEventMinute(event.target.value)}
              placeholder="Auto"
              type="number"
              value={eventMinute}
            />
          </label>

          <button
            disabled={!canWrite || isSaving || !selectedMatch}
            onClick={handleLogEvent}
            type="button"
          >
            Log event
          </button>
        </div>
      </div>

      <div className="session-controls">
        <div>
          <p className="eyebrow">Match session</p>
          <h3>Start or end the selected half</h3>
          <p>
            Current state: {selectedMatch?.statusLabel ?? 'No match selected'} ·{' '}
            {selectedMatch ? clockLabel(selectedMatch.match) : '--:--'}
          </p>
        </div>
        <div className="session-action-grid">
          <button
            disabled={!canWrite || isSaving || !selectedMatch}
            onClick={() => handleStartHalf('first')}
            type="button"
          >
            Start first half
          </button>
          <button
            disabled={!canWrite || isSaving || !selectedMatch}
            onClick={() => handleStartHalf('second')}
            type="button"
          >
            Start second half
          </button>
          <button
            disabled={!canWrite || isSaving || !selectedMatch}
            onClick={() => handleSessionAction('end')}
            type="button"
          >
            End current half
          </button>
        </div>
      </div>

      {!canWrite && (
        <p className="operation-note">
          Switch to Demo Ditto Server mode to enable browser writes.
        </p>
      )}
      {writeStatus && <p className="operation-note">{writeStatus}</p>}
      {writeError && <p className="operation-note error">{writeError}</p>}
    </section>
  )
}

function nextMatchStatus(
  action: MatchSessionInput['action'],
  half: MatchHalf,
): MatchStatus {
  if (action === 'start') {
    return half === 'first' ? 'firstHalf' : 'secondHalf'
  }

  return half === 'first' ? 'halftime' : 'fullTime'
}

function StatusCard({
  eyebrow,
  title,
  copy,
  tone,
}: {
  eyebrow: string
  title: string
  copy: string
  tone?: 'error'
}) {
  return (
    <section className={tone === 'error' ? 'status-card error' : 'status-card'}>
      <p className="eyebrow">{eyebrow}</p>
      <h2>{title}</h2>
      <p>{copy}</p>
    </section>
  )
}

function FeaturedMatch({ summary }: { summary?: MatchSummary }) {
  if (!summary) {
    return (
      <section className="featured-card empty-state">
        <p className="eyebrow">Waiting for matches</p>
        <h2>No matches yet</h2>
      </section>
    )
  }

  return (
    <section className="featured-card">
      <p className="eyebrow">Featured match</p>
      <h2>{summary.match.name}</h2>
      <div className="scoreboard">
        <span>Home</span>
        <strong>
          {summary.homeScore} : {summary.awayScore}
        </strong>
        <span>Away</span>
      </div>
      <div className="match-meta">
        <span>{summary.statusLabel}</span>
        <span>{clockLabel(summary.match)}</span>
        <span>{summary.events.length} events</span>
      </div>
      {summary.latestEvent && (
        <p className="latest-event">
          Latest: {eventLabel(summary.latestEvent.type)} —{' '}
          {eventSubject(summary.latestEvent)}
        </p>
      )}
    </section>
  )
}

function MatchGrid({
  summaries,
  selectedMatchId,
  onSelect,
}: {
  summaries: MatchSummary[]
  selectedMatchId?: string
  onSelect: (matchId: string) => void
}) {
  return (
    <section className="match-list-card">
      <div className="section-title-row">
        <div>
          <p className="eyebrow">All matches</p>
          <h2>Dashboard</h2>
        </div>
      </div>

      <div className="match-grid">
        {summaries.map((summary) => (
          <button
            className={`match-tile ${
              selectedMatchId === summary.match._id ? 'match-tile--active' : ''
            }`}
            key={summary.match._id}
            onClick={() => onSelect(summary.match._id)}
            type="button"
          >
            <span>{summary.match.name}</span>
            <strong>
              {summary.homeScore} : {summary.awayScore}
            </strong>
            <small>{summary.statusLabel}</small>
          </button>
        ))}
      </div>
    </section>
  )
}

function Timeline({ summary }: { summary?: MatchSummary }) {
  return (
    <section className="timeline-card">
      <div className="section-title-row">
        <div>
          <p className="eyebrow">Timeline</p>
          <h2>{summary ? summary.match.name : 'No match selected'}</h2>
        </div>
      </div>

      {!summary || summary.events.length === 0 ? (
        <p className="empty-copy">No events have synced for this match yet.</p>
      ) : (
        <div className="timeline">
          {summary.events.map((event) => (
            <article
              className={`timeline-event timeline-event--${
                event.teamSide ?? 'neutral'
              }`}
              key={event._id}
            >
              <span className="event-minute">{minuteLabel(event)}</span>
              <div>
                <strong>{eventLabel(event.type)}</strong>
                <p>{eventSubject(event)}</p>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  )
}
