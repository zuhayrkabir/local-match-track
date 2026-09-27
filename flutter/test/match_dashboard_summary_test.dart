import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/match_control.dart';
import 'package:local_first_match_tracker/domain/match_dashboard_summary.dart';
import 'package:local_first_match_tracker/domain/match_event.dart';
import 'package:local_first_match_tracker/domain/player.dart';

void main() {
  test('summarizes score and latest event for one match', () {
    final match = MatchControlState.initial(id: 'match-1');
    const events = [
      MatchEvent(
        id: 'event-1',
        matchId: 'match-1',
        type: MatchEventType.goal,
        teamName: 'Green FC',
        minute: 5,
        createdAtMillis: 1000,
        teamSide: TeamSide.home,
      ),
      MatchEvent(
        id: 'event-2',
        matchId: 'match-2',
        type: MatchEventType.goal,
        teamName: 'White FC',
        minute: 6,
        createdAtMillis: 2000,
        teamSide: TeamSide.away,
      ),
      MatchEvent(
        id: 'event-3',
        matchId: 'match-1',
        type: MatchEventType.yellowCard,
        teamName: 'White FC',
        minute: 7,
        createdAtMillis: 3000,
        teamSide: TeamSide.away,
      ),
    ];

    final summary = MatchDashboardSummary.fromMatch(
      match: match,
      events: events,
      nowMillis: 4000,
    );

    expect(summary.scoreLabel, '1 - 0');
    expect(summary.latestEvent?.id, 'event-3');
    expect(summary.latestEventLabel, 'Yellow card • White FC');
  });

  test('shows remaining time for a running half', () {
    const match = MatchControlState(
      id: 'match-1',
      name: 'Clock match',
      selectedHalf: MatchHalf.first,
      status: MatchStatus.firstHalf,
      createdAtMillis: 1000000,
      updatedAtMillis: 1000000,
      elapsedSeconds: 60,
      clockStartedAtMillis: 1000000,
    );

    final summary = MatchDashboardSummary.fromMatch(
      match: match,
      events: const [],
      nowMillis: 1120000,
    );

    expect(summary.clockLabel, '03:00');
    expect(summary.timeRemainingLabel, '42:00 remaining');
  });

  test('shows full-time matches as having no remaining time', () {
    const match = MatchControlState(
      id: 'match-1',
      name: 'Finished match',
      selectedHalf: MatchHalf.second,
      status: MatchStatus.fullTime,
      createdAtMillis: 1000000,
      updatedAtMillis: 1000000,
      elapsedSeconds: 2700,
    );

    final summary = MatchDashboardSummary.fromMatch(
      match: match,
      events: const [],
      nowMillis: 2000000,
    );

    expect(summary.timeRemainingLabel, '00:00 remaining');
    expect(summary.latestEventLabel, 'No events yet');
  });
}
