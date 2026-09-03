import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/match_event.dart';
import 'package:local_first_match_tracker/domain/player.dart';

void main() {
  test('serializes and deserializes a goal event', () {
    const event = MatchEvent(
      id: 'event-1',
      matchId: 'demo-match',
      type: MatchEventType.goal,
      teamName: 'Green FC',
      minute: 34,
      createdAtMillis: 123456789,
      playerId: 'home-7',
      playerName: 'A. Khan',
      playerNumber: 7,
      teamSide: TeamSide.home,
    );

    final restored = MatchEvent.fromJson(event.toJson());

    expect(restored.id, 'event-1');
    expect(restored.matchId, 'demo-match');
    expect(restored.type, MatchEventType.goal);
    expect(restored.teamName, 'Green FC');
    expect(restored.minute, 34);
    expect(restored.createdAtMillis, 123456789);
    expect(restored.playerId, 'home-7');
    expect(restored.playerName, 'A. Khan');
    expect(restored.playerNumber, 7);
    expect(restored.teamSide, TeamSide.home);
    expect(restored.label, 'Goal');
    expect(restored.subjectLabel, 'Green FC #7 — A. Khan');
  });

  test('handles older synced events without player fields', () {
    final restored = MatchEvent.fromJson({
      '_id': 'event-legacy',
      'matchId': 'demo-match',
      'type': 'goal',
      'teamName': 'Green FC',
      'minute': 12,
      'createdAtMillis': 123,
    });

    expect(restored.playerId, isNull);
    expect(restored.playerName, isNull);
    expect(restored.playerNumber, isNull);
    expect(restored.teamSide, isNull);
    expect(restored.subjectLabel, 'Green FC');
  });

  test('serializes substitution player on and off fields', () {
    const event = MatchEvent(
      id: 'event-sub',
      matchId: 'demo-match',
      type: MatchEventType.substitution,
      teamName: 'Green FC',
      minute: 65,
      createdAtMillis: 123456789,
      playerId: 'home-7',
      playerName: 'A. Khan',
      playerNumber: 7,
      substitutePlayerId: 'home-14',
      substitutePlayerName: 'H. Singh',
      substitutePlayerNumber: 14,
      teamSide: TeamSide.home,
    );

    final restored = MatchEvent.fromJson(event.toJson());

    expect(restored.type, MatchEventType.substitution);
    expect(restored.substitutePlayerId, 'home-14');
    expect(restored.substitutePlayerName, 'H. Singh');
    expect(restored.substitutePlayerNumber, 14);
    expect(
      restored.subjectLabel,
      'Green FC #14 — H. Singh on, #7 — A. Khan off',
    );
  });
}
