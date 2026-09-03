import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_first_match_tracker/app/providers.dart';
import 'package:local_first_match_tracker/ditto/ditto_manager.dart';
import 'package:local_first_match_tracker/domain/app_role.dart';
import 'package:local_first_match_tracker/domain/match_control.dart';
import 'package:local_first_match_tracker/domain/match_event.dart';
import 'package:local_first_match_tracker/domain/player.dart';
import 'package:local_first_match_tracker/features/match_events/match_events_screen.dart';

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
}
