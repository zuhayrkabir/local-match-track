import { useMemo, useState } from 'react'
import {
  buildSummaries,
  clockLabel,
  eventLabel,
  eventSubject,
  minuteLabel,
} from './domain/matchProjection'
import type { MatchSummary } from './domain/matchTypes'
import { sampleEvents, sampleMatches } from './sampleData'

export default function App() {
  const summaries = useMemo(
    () => buildSummaries(sampleMatches, sampleEvents),
    [],
  )

  const [selectedMatchId, setSelectedMatchId] = useState<string | undefined>()
  const selectedMatch =
    summaries.find((summary) => summary.match._id === selectedMatchId) ??
    summaries[0]

  return (
    <main className="app-shell">
      <header className="hero">
        <div>
          <p className="eyebrow">React Web checkpoint</p>
          <h1>Local-First Match Center</h1>
          <p>
            This first browser checkpoint mirrors the Flutter dashboard UI and
            shared match projection without exposing a Ditto playground token in
            client-side JavaScript.
          </p>
        </div>
        <div className="sync-card">
          <span>Status</span>
          <strong>Safe</strong>
          <small>UI scaffold, no browser token yet</small>
        </div>
      </header>

      <section className="notice-card">
        <p className="eyebrow">Ditto Web next step</p>
        <p>
          The browser app is ready for Ditto Web wiring, but server auth needs a
          deliberate demo/security decision because any token bundled into React
          can be inspected by users.
        </p>
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
    </main>
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
