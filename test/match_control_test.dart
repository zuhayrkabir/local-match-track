import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/match_control.dart';

void main() {
  test('initial match control state starts before kickoff', () {
    final state = MatchControlState.initial();

    expect(state.id, MatchControlState.demoMatchId);
    expect(state.name, 'Demo match');
    expect(state.selectedHalf, MatchHalf.first);
    expect(state.status, MatchStatus.notStarted);
    expect(state.statusLabel, 'Not started');
    expect(state.isHalfRunning, isFalse);
  });

  test('serializes and deserializes selected half and status', () {
    const state = MatchControlState(
      id: MatchControlState.demoMatchId,
      name: 'Scrimmage',
      selectedHalf: MatchHalf.second,
      status: MatchStatus.secondHalf,
      createdAtMillis: 123456789,
      updatedAtMillis: 987654321,
      elapsedSeconds: 125,
      clockStartedAtMillis: 1000000,
    );

    final restored = MatchControlState.fromJson(state.toJson());

    expect(restored.selectedHalf, MatchHalf.second);
    expect(restored.name, 'Scrimmage');
    expect(restored.status, MatchStatus.secondHalf);
    expect(restored.createdAtMillis, 123456789);
    expect(restored.updatedAtMillis, 987654321);
    expect(restored.elapsedSeconds, 125);
    expect(restored.clockStartedAtMillis, 1000000);
    expect(restored.selectedHalfLabel, 'Second half');
    expect(restored.statusLabel, 'Second half live');
    expect(restored.isHalfRunning, isTrue);
  });

  test('calculates a running first half clock and match minute', () {
    const state = MatchControlState(
      id: MatchControlState.demoMatchId,
      name: 'Clock test',
      selectedHalf: MatchHalf.first,
      status: MatchStatus.firstHalf,
      createdAtMillis: 1000000,
      updatedAtMillis: 1000000,
      elapsedSeconds: 0,
      clockStartedAtMillis: 1000000,
    );

    expect(state.elapsedSecondsAt(1125000), 125);
    expect(state.clockLabelAt(1125000), '02:05');
    expect(state.matchMinuteAt(1125000), 3);
  });

  test('adds the second half offset to match minute', () {
    const state = MatchControlState(
      id: MatchControlState.demoMatchId,
      name: 'Second half test',
      selectedHalf: MatchHalf.second,
      status: MatchStatus.secondHalf,
      createdAtMillis: 1000000,
      updatedAtMillis: 1000000,
      elapsedSeconds: 60,
      clockStartedAtMillis: 1000000,
    );

    expect(state.matchMinuteAt(1000000), 47);
  });

  test('falls back safely for malformed synced state', () {
    final restored = MatchControlState.fromJson({
      '_id': MatchControlState.demoMatchId,
      'selectedHalf': 'thirdHalf',
      'status': 'weatherDelay',
      'updatedAtMillis': 'not-a-number',
    });

    expect(restored.selectedHalf, MatchHalf.first);
    expect(restored.status, MatchStatus.notStarted);
    expect(restored.updatedAtMillis, 0);
  });
}
