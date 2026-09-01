import 'match_control.dart';
import 'match_event.dart';
import 'player.dart';

class MatchDashboardSummary {
  const MatchDashboardSummary({
    required this.match,
    required this.homeGoals,
    required this.awayGoals,
    required this.latestEvent,
    required this.clockLabel,
    required this.timeRemainingLabel,
  });

  static const halfDurationSeconds = 45 * 60;

  factory MatchDashboardSummary.fromMatch({
    required MatchControlState match,
    required List<MatchEvent> events,
    required int nowMillis,
  }) {
    final matchEvents =
        events.where((event) => event.matchId == match.id).toList()
          ..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis));

    return MatchDashboardSummary(
      match: match,
      homeGoals: _goalsFor(matchEvents, TeamSide.home),
      awayGoals: _goalsFor(matchEvents, TeamSide.away),
      latestEvent: matchEvents.isEmpty ? null : matchEvents.last,
      clockLabel: match.clockLabelAt(nowMillis),
      timeRemainingLabel: _timeRemainingLabel(match, nowMillis),
    );
  }

  final MatchControlState match;
  final int homeGoals;
  final int awayGoals;
  final MatchEvent? latestEvent;
  final String clockLabel;
  final String timeRemainingLabel;

  String get scoreLabel => '$homeGoals - $awayGoals';

  String get latestEventLabel {
    final event = latestEvent;
    if (event == null) {
      return 'No events yet';
    }
    return '${event.label} • ${event.subjectLabel}';
  }

  static int _goalsFor(List<MatchEvent> events, TeamSide side) {
    return events
        .where(
          (event) =>
              event.type == MatchEventType.goal &&
              (event.teamSide == side ||
                  event.teamName == teamNameForSide(side)),
        )
        .length;
  }

  static String _timeRemainingLabel(MatchControlState match, int nowMillis) {
    if (match.status == MatchStatus.fullTime) {
      return '00:00 remaining';
    }

    final elapsedInHalf = match.elapsedSecondsAt(nowMillis);
    final remainingSeconds = (halfDurationSeconds - elapsedInHalf).clamp(
      0,
      halfDurationSeconds,
    );
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')} remaining';
  }
}
