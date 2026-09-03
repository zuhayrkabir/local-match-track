import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_first_match_tracker/app/providers.dart';
import 'package:local_first_match_tracker/ditto/ditto_manager.dart';
import 'package:local_first_match_tracker/domain/app_role.dart';
import 'package:local_first_match_tracker/domain/match_control.dart';
import 'package:local_first_match_tracker/domain/match_event.dart';
import 'package:local_first_match_tracker/domain/match_review_proposal.dart';
import 'package:local_first_match_tracker/domain/player.dart';
import 'package:local_first_match_tracker/features/match_events/match_events_screen.dart';
import 'package:local_first_match_tracker/repositories/match_event_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('official referee event picker includes ordinary fouls', () {
    expect(officialRefereeEventTypes, contains(MatchEventType.foul));
  });

  testWidgets('detail timeline follows the selected match on compact screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const selectedMatch = MatchControlState(
      id: 'match-2',
      name: 'Selected Match',
      selectedHalf: MatchHalf.first,
      status: MatchStatus.firstHalf,
      createdAtMillis: 1000,
      updatedAtMillis: 2000,
      elapsedSeconds: 60,
      clockStartedAtMillis: 1000,
    );

    const otherMatch = MatchControlState(
      id: 'match-1',
      name: 'Other Match',
      selectedHalf: MatchHalf.first,
      status: MatchStatus.firstHalf,
      createdAtMillis: 1000,
      updatedAtMillis: 1000,
      elapsedSeconds: 60,
      clockStartedAtMillis: 1000,
    );

    const events = [
      MatchEvent(
        id: 'neutral-event',
        matchId: 'match-2',
        type: MatchEventType.halfStarted,
        teamName: 'First half',
        minute: 0,
        createdAtMillis: 500,
      ),
      MatchEvent(
        id: 'other-event',
        matchId: 'match-1',
        type: MatchEventType.goal,
        teamName: 'Wrong Match FC',
        minute: 4,
        createdAtMillis: 1000,
        teamSide: TeamSide.home,
      ),
      MatchEvent(
        id: 'selected-event',
        matchId: 'match-2',
        type: MatchEventType.yellowCard,
        teamName: 'Selected Match FC',
        minute: 9,
        createdAtMillis: 2000,
        teamSide: TeamSide.away,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRoleProvider.overrideWith((ref) => AppRole.spectator),
          showDashboardProvider.overrideWith((ref) => false),
          selectedMatchIdProvider.overrideWith((ref) => 'match-2'),
          dittoManagerProvider.overrideWith((ref) {
            throw StateError('Ditto is not needed for this widget test.');
          }),
          matchesProvider.overrideWith(
            (ref) => Stream.value(const [selectedMatch, otherMatch]),
          ),
          matchControlProvider.overrideWith(
            (ref) => Stream.value(selectedMatch),
          ),
          allMatchEventsProvider.overrideWith((ref) => Stream.value(events)),
          dittoPresenceSummaryProvider.overrideWith(
            (ref) => Stream.value(
              const DittoPresenceSummary(
                localPeerName: 'Test peer',
                remotePeerCount: 0,
                connectedToDittoServer: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: MatchEventsScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Selected Match FC'), findsOneWidget);
    expect(find.textContaining('Wrong Match FC'), findsNothing);
    expect(find.text('GREEN FC'), findsOneWidget);
    expect(find.text('WHITE FC'), findsOneWidget);
    expect(find.text('Half started • 0’'), findsOneWidget);
    expect(find.text('Yellow card'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Half started • 0’')).dx,
      closeTo(195, 36),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('referee create match opens the new match detail view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeMatchEventRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRoleProvider.overrideWith((ref) => AppRole.referee),
          showDashboardProvider.overrideWith((ref) => true),
          selectedMatchIdProvider.overrideWith((ref) => 'match-1'),
          dittoManagerProvider.overrideWith(
            (ref) async => _ReadyDittoManager(),
          ),
          matchEventRepositoryProvider.overrideWith((ref) async => repository),
          dittoPresenceSummaryProvider.overrideWith(
            (ref) => Stream.value(
              const DittoPresenceSummary(
                localPeerName: 'Test peer',
                remotePeerCount: 0,
                connectedToDittoServer: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: MatchEventsScreen()),
      ),
    );

    await tester.pump();
    expect(find.text('MATCH CENTRE'), findsOneWidget);

    await tester.tap(find.text('New match'));
    await tester.pumpAndSettle();

    expect(repository.createdMatchCount, 1);
    expect(find.text('MATCH SESSION'), findsOneWidget);
    expect(find.text('MATCH CENTRE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('referee can rename the selected match', (tester) async {
    tester.view.physicalSize = const Size(390, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeMatchEventRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedRoleProvider.overrideWith((ref) => AppRole.referee),
          showDashboardProvider.overrideWith((ref) => false),
          selectedMatchIdProvider.overrideWith((ref) => 'match-1'),
          dittoManagerProvider.overrideWith(
            (ref) async => _ReadyDittoManager(),
          ),
          matchEventRepositoryProvider.overrideWith((ref) async => repository),
          dittoPresenceSummaryProvider.overrideWith(
            (ref) => Stream.value(
              const DittoPresenceSummary(
                localPeerName: 'Test peer',
                remotePeerCount: 0,
                connectedToDittoServer: false,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: MatchEventsScreen()),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Rename match'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'U18 Semifinal');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.renamedMatchId, 'match-1');
    expect(repository.renamedMatchName, 'U18 Semifinal');
    expect(tester.takeException(), isNull);
  });
}

class _ReadyDittoManager extends DittoManager {
  @override
  bool get dataAccessReady => true;

  @override
  String get activationMessage => 'Ready for tests.';

  @override
  String get modeLabel => 'Test mode';

  @override
  Stream<DittoPresenceSummary> watchPresence() {
    return Stream.value(
      const DittoPresenceSummary(
        localPeerName: 'Test peer',
        remotePeerCount: 0,
        connectedToDittoServer: false,
      ),
    );
  }

  @override
  Future<void> close() async {}
}

class _FakeMatchEventRepository implements MatchEventRepository {
  static const _initialMatch = MatchControlState(
    id: 'match-1',
    name: 'Demo match',
    selectedHalf: MatchHalf.first,
    status: MatchStatus.notStarted,
    createdAtMillis: 1000,
    updatedAtMillis: 1000,
    elapsedSeconds: 0,
  );

  int createdMatchCount = 0;
  String? renamedMatchId;
  String? renamedMatchName;

  @override
  Stream<List<MatchControlState>> watchMatches() {
    return Stream.value(const [_initialMatch]);
  }

  @override
  Stream<MatchControlState> watchMatchControl() {
    return Stream.value(_initialMatch);
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
  Stream<List<MatchReviewProposal>> watchPendingReviewProposals() {
    return Stream.value(const []);
  }

  @override
  Stream<bool> watchRefereeOnline() {
    return Stream.value(true);
  }

  @override
  Future<MatchControlState> createMatch() async {
    createdMatchCount += 1;
    return MatchControlState.initial(
      id: 'match-created',
      name: 'Created Match',
    );
  }

  @override
  Future<void> renameMatch({
    required String matchId,
    required String name,
  }) async {
    renamedMatchId = matchId;
    renamedMatchName = name;
  }

  @override
  Future<void> deleteMatch(String matchId) async {}

  @override
  Future<void> selectHalf(MatchHalf half) async {}

  @override
  Future<void> startSelectedHalf() async {}

  @override
  Future<void> endCurrentHalf() async {}

  @override
  Future<void> addOfficialEvent({
    required MatchEventType type,
    required TeamSide teamSide,
    DemoPlayer? player,
  }) async {}

  @override
  Future<void> addSubstitution({
    required TeamSide teamSide,
    required DemoPlayer playerOut,
    required DemoPlayer playerIn,
  }) async {}

  @override
  Future<void> addTestGoal() async {}

  @override
  Future<void> proposeReview({
    required MatchEventType type,
    required TeamSide teamSide,
    DemoPlayer? player,
  }) async {}

  @override
  Future<void> acceptReviewProposal(MatchReviewProposal proposal) async {}

  @override
  Future<void> rejectReviewProposal(MatchReviewProposal proposal) async {}

  @override
  Future<void> publishParticipantHeartbeat(AppRole role) async {}
}
