import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/match_event.dart';

void main() {
  test('serializes and deserializes a goal event', () {
    const event = MatchEvent(
      id: 'event-1',
      matchId: 'demo-match',
      type: MatchEventType.goal,
      teamName: 'Green FC',
      minute: 34,
      createdAtMillis: 123456789,
    );

    final restored = MatchEvent.fromJson(event.toJson());

    expect(restored.id, 'event-1');
    expect(restored.matchId, 'demo-match');
    expect(restored.type, MatchEventType.goal);
    expect(restored.teamName, 'Green FC');
    expect(restored.minute, 34);
    expect(restored.createdAtMillis, 123456789);
    expect(restored.label, 'Goal');
  });
}
