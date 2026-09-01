import '../domain/match_event.dart';
import '../domain/match_control.dart';
import '../domain/player.dart';

abstract interface class MatchEventRepository {
  Stream<List<MatchControlState>> watchMatches();

  Stream<MatchControlState> watchMatchControl();

  Stream<List<MatchEvent>> watchEvents();

  Stream<List<MatchEvent>> watchAllEvents();

  Future<MatchControlState> createMatch();

  Future<void> deleteMatch(String matchId);

  Future<void> selectHalf(MatchHalf half);

  Future<void> startSelectedHalf();

  Future<void> endCurrentHalf();

  Future<void> addOfficialEvent({
    required MatchEventType type,
    required TeamSide teamSide,
    DemoPlayer? player,
  });

  Future<void> addSubstitution({
    required TeamSide teamSide,
    required DemoPlayer playerOut,
    required DemoPlayer playerIn,
  });

  Future<void> addTestGoal();
}

class DisabledMatchEventRepository implements MatchEventRepository {
  const DisabledMatchEventRepository(this.reason);

  final String reason;

  @override
  Stream<List<MatchControlState>> watchMatches() {
    return Stream.value([MatchControlState.initial()]);
  }

  @override
  Stream<MatchControlState> watchMatchControl() {
    return Stream.value(MatchControlState.initial());
  }

  @override
  Stream<List<MatchEvent>> watchEvents() {
    return Stream.value(const []);
  }

  @override
  Stream<List<MatchEvent>> watchAllEvents() {
    return Stream.value(const []);
  }

  @override
  Future<MatchControlState> createMatch() {
    throw StateError(reason);
  }

  @override
  Future<void> deleteMatch(String matchId) {
    throw StateError(reason);
  }

  @override
  Future<void> selectHalf(MatchHalf half) {
    throw StateError(reason);
  }

  @override
  Future<void> startSelectedHalf() {
    throw StateError(reason);
  }

  @override
  Future<void> endCurrentHalf() {
    throw StateError(reason);
  }

  @override
  Future<void> addOfficialEvent({
    required MatchEventType type,
    required TeamSide teamSide,
    DemoPlayer? player,
  }) {
    throw StateError(reason);
  }

  @override
  Future<void> addSubstitution({
    required TeamSide teamSide,
    required DemoPlayer playerOut,
    required DemoPlayer playerIn,
  }) {
    throw StateError(reason);
  }

  @override
  Future<void> addTestGoal() {
    throw StateError(reason);
  }
}
