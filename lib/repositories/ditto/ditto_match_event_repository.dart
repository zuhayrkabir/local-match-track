import 'dart:async';
import 'dart:math';

import 'package:ditto_live/ditto_live.dart';

import '../../ditto/ditto_manager.dart';
import '../../domain/match_event.dart';
import '../match_event_repository.dart';

class DittoMatchEventRepository implements MatchEventRepository {
  DittoMatchEventRepository(this._manager);

  static const _demoMatchId = 'demo-match';

  final DittoManager _manager;

  Ditto get _ditto => _manager.ditto;

  @override
  Stream<List<MatchEvent>> watchEvents() {
    final controller = StreamController<List<MatchEvent>>();
    late final StoreObserver observer;

    Future<void> emit(QueryResult result) async {
      final events =
          result.items.map((item) => MatchEvent.fromJson(item.value)).toList()
            ..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis));

      if (!controller.isClosed) {
        controller.add(events);
      }
    }

    Future<void> loadInitialEvents() async {
      final result = await _ditto.store.execute(
        'SELECT * FROM match_events ORDER BY createdAtMillis ASC',
      );
      await emit(result);
    }

    observer = _ditto.store.registerObserver(
      'SELECT * FROM match_events ORDER BY createdAtMillis ASC',
      onChange: (result) {
        unawaited(emit(result));
      },
    );

    unawaited(loadInitialEvents());

    controller.onCancel = observer.cancel;
    return controller.stream;
  }

  @override
  Future<void> addTestGoal() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final event = MatchEvent(
      id: 'event-$now-${Random().nextInt(100000)}',
      matchId: _demoMatchId,
      type: MatchEventType.goal,
      teamName: 'Green FC',
      minute: DateTime.now().minute,
      createdAtMillis: now,
    );

    await _ditto.store.execute(
      '''
      INSERT INTO match_events DOCUMENTS (:event)
      ON ID CONFLICT DO UPDATE_LOCAL_DIFF
      ''',
      arguments: {'event': event.toJson()},
    );
  }
}
