import { useMemo, useState } from 'react'
import { DittoProvider, useQuery, useRemotePeers } from '@dittolive/react-ditto'
import {
  buildSummaries,
  clockLabel,
  eventLabel,
  eventSubject,
  minuteLabel,
} from './domain/matchProjection'
import type {
  MatchDocument,
  MatchEventDocument,
  MatchSummary,
} from './domain/matchTypes'
import { sampleEvents, sampleMatches } from './sampleData'
import { createDemoDitto } from './services/createDemoDitto'

type AppMode = 'sample' | 'ditto'

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
      <Dashboard
        summaries={summaries}
        peerCount={remotePeers.length}
        sourceLabel={
          matchesQuery.isLoading || eventsQuery.isLoading ? 'Loading' : 'Ditto'
        }
      />
    </>
  )
}

function Dashboard({
  summaries,
  peerCount,
  sourceLabel,
}: {
  summaries: MatchSummary[]
  peerCount: number
  sourceLabel: string
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
