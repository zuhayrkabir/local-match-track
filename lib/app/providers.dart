import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ditto/ditto_manager.dart';
import '../domain/match_event.dart';
import '../repositories/ditto/ditto_match_event_repository.dart';
import '../repositories/match_event_repository.dart';

final dittoManagerProvider = FutureProvider<DittoManager>((ref) async {
  final manager = DittoManager();
  ref.onDispose(manager.close);
  await manager.open();
  return manager;
});

final matchEventRepositoryProvider = FutureProvider<MatchEventRepository>((
  ref,
) async {
  final manager = await ref.watch(dittoManagerProvider.future);
  if (!manager.dataAccessReady) {
    return DisabledMatchEventRepository(manager.activationMessage);
  }
  return DittoMatchEventRepository(manager);
});

final matchEventsProvider = StreamProvider<List<MatchEvent>>((ref) async* {
  final repository = await ref.watch(matchEventRepositoryProvider.future);
  yield* repository.watchEvents();
});

final dittoPresenceSummaryProvider = StreamProvider<DittoPresenceSummary>((
  ref,
) async* {
  final manager = await ref.watch(dittoManagerProvider.future);
  yield* manager.watchPresence();
});
