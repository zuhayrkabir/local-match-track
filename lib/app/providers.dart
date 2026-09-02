import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ditto/ditto_manager.dart';
import '../domain/app_role.dart';
import '../domain/match_control.dart';
import '../domain/match_event.dart';
import '../domain/match_review_proposal.dart';
import '../repositories/ditto/ditto_match_event_repository.dart';
import '../repositories/match_event_repository.dart';

final selectedRoleProvider = StateProvider<AppRole?>((ref) => null);

final showDashboardProvider = StateProvider<bool>((ref) => true);

final selectedMatchIdProvider = StateProvider<String>(
  (ref) => MatchControlState.demoMatchId,
);

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
  final matchId = ref.watch(selectedMatchIdProvider);
  if (!manager.dataAccessReady) {
    return DisabledMatchEventRepository(manager.activationMessage);
  }
  return DittoMatchEventRepository(manager, matchId: matchId);
});

final matchesProvider = StreamProvider<List<MatchControlState>>((ref) async* {
  final repository = await ref.watch(matchEventRepositoryProvider.future);
  yield* repository.watchMatches();
});

final matchEventsProvider = StreamProvider<List<MatchEvent>>((ref) async* {
  final repository = await ref.watch(matchEventRepositoryProvider.future);
  yield* repository.watchEvents();
});

final allMatchEventsProvider = StreamProvider<List<MatchEvent>>((ref) async* {
  final repository = await ref.watch(matchEventRepositoryProvider.future);
  yield* repository.watchAllEvents();
});

final pendingReviewProposalsProvider =
    StreamProvider<List<MatchReviewProposal>>((ref) async* {
      final repository = await ref.watch(matchEventRepositoryProvider.future);
      yield* repository.watchPendingReviewProposals();
    });

final refereeOnlineProvider = StreamProvider<bool>((ref) async* {
  final repository = await ref.watch(matchEventRepositoryProvider.future);
  yield* repository.watchRefereeOnline();
});

final matchControlProvider = StreamProvider<MatchControlState>((ref) async* {
  final repository = await ref.watch(matchEventRepositoryProvider.future);
  yield* repository.watchMatchControl();
});

final dittoPresenceSummaryProvider = StreamProvider<DittoPresenceSummary>((
  ref,
) async* {
  final manager = await ref.watch(dittoManagerProvider.future);
  yield* manager.watchPresence();
});
