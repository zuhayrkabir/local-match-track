import '../domain/match_event.dart';

abstract interface class MatchEventRepository {
  Stream<List<MatchEvent>> watchEvents();

  Future<void> addTestGoal();
}

class DisabledMatchEventRepository implements MatchEventRepository {
  const DisabledMatchEventRepository(this.reason);

  final String reason;

  @override
  Stream<List<MatchEvent>> watchEvents() {
    return Stream.value(const []);
  }

  @override
  Future<void> addTestGoal() {
    throw StateError(reason);
  }
}
