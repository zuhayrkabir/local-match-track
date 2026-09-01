import 'dart:async';
import 'dart:math';

import 'package:ditto_live/ditto_live.dart';

import '../../ditto/ditto_manager.dart';
import '../../domain/match_control.dart';
import '../../domain/match_event.dart';
import '../../domain/player.dart';
import '../match_event_repository.dart';

class DittoMatchEventRepository implements MatchEventRepository {
  DittoMatchEventRepository(this._manager, {required this._matchId});

  final DittoManager _manager;
  final String _matchId;

  Ditto get _ditto => _manager.ditto;

  @override
  Stream<List<MatchControlState>> watchMatches() {
    final controller = StreamController<List<MatchControlState>>();
    late final StoreObserver observer;

    Future<void> emit(QueryResult result) async {
      final matches =
          result.items
              .map((item) => MatchControlState.fromJson(item.value))
              .toList()
            ..sort((a, b) => b.updatedAtMillis.compareTo(a.updatedAtMillis));

      if (!controller.isClosed) {
        controller.add(
          matches.isEmpty ? [MatchControlState.initial()] : matches,
        );
      }
    }

    Future<void> loadInitialMatches() async {
      final result = await _ditto.store.execute(
        'SELECT * FROM matches ORDER BY updatedAtMillis DESC',
      );
      await emit(result);
    }

    observer = _ditto.store.registerObserver(
      'SELECT * FROM matches ORDER BY updatedAtMillis DESC',
      onChange: (result) {
        unawaited(emit(result));
      },
    );

    unawaited(loadInitialMatches());

    controller.onCancel = observer.cancel;
    return controller.stream;
  }

  @override
  Stream<MatchControlState> watchMatchControl() {
    final controller = StreamController<MatchControlState>();
    late final StoreObserver observer;

    Future<void> emit(QueryResult result) async {
      final state = result.items.isEmpty
          ? MatchControlState.initial(id: _matchId)
          : MatchControlState.fromJson(result.items.first.value);

      if (!controller.isClosed) {
        controller.add(state);
      }
    }

    Future<void> loadInitialState() async {
      final result = await _ditto.store.execute(
        'SELECT * FROM matches WHERE _id = :matchId',
        arguments: {'matchId': _matchId},
      );
      await emit(result);
    }

    observer = _ditto.store.registerObserver(
      'SELECT * FROM matches WHERE _id = :matchId',
      arguments: {'matchId': _matchId},
      onChange: (result) {
        unawaited(emit(result));
      },
    );

    unawaited(loadInitialState());

    controller.onCancel = observer.cancel;
    return controller.stream;
  }

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
        '''
        SELECT * FROM match_events
        WHERE matchId = :matchId
        ORDER BY createdAtMillis ASC
        ''',
        arguments: {'matchId': _matchId},
      );
      await emit(result);
    }

    observer = _ditto.store.registerObserver(
      '''
      SELECT * FROM match_events
      WHERE matchId = :matchId
      ORDER BY createdAtMillis ASC
      ''',
      arguments: {'matchId': _matchId},
      onChange: (result) {
        unawaited(emit(result));
      },
    );

    unawaited(loadInitialEvents());

    controller.onCancel = observer.cancel;
    return controller.stream;
  }

  @override
  Future<MatchControlState> createMatch() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final match = MatchControlState.initial(
      id: 'match-$now-${Random().nextInt(100000)}',
      name:
          'Match ${DateTime.now().month}/${DateTime.now().day} '
          '${DateTime.now().hour.toString().padLeft(2, '0')}:'
          '${DateTime.now().minute.toString().padLeft(2, '0')}',
    ).copyWith(createdAtMillis: now, updatedAtMillis: now);

    await _saveMatchControl(match);
    return match;
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    await _ditto.store.execute(
      'DELETE FROM match_events WHERE matchId = :matchId',
      arguments: {'matchId': matchId},
    );
    await _ditto.store.execute(
      'DELETE FROM matches WHERE _id = :matchId',
      arguments: {'matchId': matchId},
    );
  }

  @override
  Future<void> selectHalf(MatchHalf half) async {
    final current = await _readMatchControl();
    await _saveMatchControl(
      current.copyWith(
        selectedHalf: half,
        elapsedSeconds: 0,
        clearClockStartedAt: true,
        updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> startSelectedHalf() async {
    final current = await _readMatchControl();
    final startedStatus = switch (current.selectedHalf) {
      MatchHalf.first => MatchStatus.firstHalf,
      MatchHalf.second => MatchStatus.secondHalf,
    };
    final now = DateTime.now().millisecondsSinceEpoch;

    await _saveMatchControl(
      current.copyWith(
        status: startedStatus,
        elapsedSeconds: 0,
        clockStartedAtMillis: now,
        updatedAtMillis: now,
      ),
    );
    await _insertEvent(
      MatchEvent(
        id: _newEventId(now),
        matchId: _matchId,
        type: MatchEventType.halfStarted,
        teamName: current.selectedHalfLabel,
        minute: current.copyWith(status: startedStatus).matchMinuteAt(now),
        createdAtMillis: now,
      ),
    );
  }

  @override
  Future<void> endCurrentHalf() async {
    final current = await _readMatchControl();
    final endedHalf = switch (current.status) {
      MatchStatus.firstHalf => MatchHalf.first,
      MatchStatus.secondHalf => MatchHalf.second,
      _ => current.selectedHalf,
    };
    final nextStatus = switch (endedHalf) {
      MatchHalf.first => MatchStatus.halftime,
      MatchHalf.second => MatchStatus.fullTime,
    };
    final now = DateTime.now().millisecondsSinceEpoch;
    final finalElapsedSeconds = current.elapsedSecondsAt(now);

    await _saveMatchControl(
      current.copyWith(
        selectedHalf: endedHalf,
        status: nextStatus,
        elapsedSeconds: finalElapsedSeconds,
        clearClockStartedAt: true,
        updatedAtMillis: now,
      ),
    );
    await _insertEvent(
      MatchEvent(
        id: _newEventId(now),
        matchId: _matchId,
        type: MatchEventType.halfEnded,
        teamName: switch (endedHalf) {
          MatchHalf.first => 'First half',
          MatchHalf.second => 'Second half',
        },
        minute: current.matchMinuteAt(now),
        createdAtMillis: now,
      ),
    );
  }

  @override
  Future<void> addOfficialEvent({
    required MatchEventType type,
    required TeamSide teamSide,
    DemoPlayer? player,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final match = await _readMatchControl();
    await _insertEvent(
      MatchEvent(
        id: _newEventId(now),
        matchId: _matchId,
        type: type,
        teamName: teamNameForSide(teamSide),
        minute: match.matchMinuteAt(now),
        createdAtMillis: now,
        playerId: player?.id,
        playerName: player?.name,
        playerNumber: player?.number,
        teamSide: teamSide,
      ),
    );
  }

  @override
  Future<void> addSubstitution({
    required TeamSide teamSide,
    required DemoPlayer playerOut,
    required DemoPlayer playerIn,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final match = await _readMatchControl();
    await _insertEvent(
      MatchEvent(
        id: _newEventId(now),
        matchId: _matchId,
        type: MatchEventType.substitution,
        teamName: teamNameForSide(teamSide),
        minute: match.matchMinuteAt(now),
        createdAtMillis: now,
        playerId: playerOut.id,
        playerName: playerOut.name,
        playerNumber: playerOut.number,
        substitutePlayerId: playerIn.id,
        substitutePlayerName: playerIn.name,
        substitutePlayerNumber: playerIn.number,
        teamSide: teamSide,
      ),
    );
  }

  @override
  Future<void> addTestGoal() async {
    await addOfficialEvent(
      type: MatchEventType.goal,
      teamSide: TeamSide.home,
      player: demoPlayers.first,
    );
  }

  Future<MatchControlState> _readMatchControl() async {
    final result = await _ditto.store.execute(
      'SELECT * FROM matches WHERE _id = :matchId',
      arguments: {'matchId': _matchId},
    );

    if (result.items.isEmpty) {
      return MatchControlState.initial(id: _matchId);
    }
    return MatchControlState.fromJson(result.items.first.value);
  }

  Future<void> _saveMatchControl(MatchControlState state) async {
    await _ditto.store.execute(
      '''
      INSERT INTO matches DOCUMENTS (:match)
      ON ID CONFLICT DO UPDATE_LOCAL_DIFF
      ''',
      arguments: {'match': state.toJson()},
    );
  }

  Future<void> _insertEvent(MatchEvent event) async {
    await _ditto.store.execute(
      '''
      INSERT INTO match_events DOCUMENTS (:event)
      ON ID CONFLICT DO UPDATE_LOCAL_DIFF
      ''',
      arguments: {'event': event.toJson()},
    );
  }

  String _newEventId(int now) => 'event-$now-${Random().nextInt(100000)}';
}
