import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/app_role.dart';
import 'package:local_first_match_tracker/domain/match_participant.dart';

void main() {
  test('serializes referee heartbeat participant state', () {
    const participant = MatchParticipant(
      id: 'participant-peer-match-1',
      matchId: 'match-1',
      role: AppRole.referee,
      deviceName: 'Referee Phone',
      lastSeenMillis: 123456789,
    );

    expect(participant.toJson(), {
      '_id': 'participant-peer-match-1',
      'matchId': 'match-1',
      'role': 'referee',
      'deviceName': 'Referee Phone',
      'lastSeenMillis': 123456789,
    });
  });

  test('falls back safely for malformed participant documents', () {
    final participant = MatchParticipant.fromJson({
      '_id': 'participant-bad',
      'matchId': 'match-1',
      'role': 'unexpected-role',
      'lastSeenMillis': 'not-a-number',
    });

    expect(participant.id, 'participant-bad');
    expect(participant.matchId, 'match-1');
    expect(participant.role, AppRole.spectator);
    expect(participant.deviceName, 'Unknown device');
    expect(participant.lastSeenMillis, 0);
  });
}
