import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_first_match_tracker/ditto/ditto_manager.dart';
import 'package:local_first_match_tracker/domain/match_control.dart';
import 'package:local_first_match_tracker/domain/match_event.dart';
import 'package:local_first_match_tracker/domain/player.dart';
import 'package:local_first_match_tracker/features/match_dashboard/match_dashboard_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders team-sided timeline events without layout exceptions', (
    tester,
  ) async {
    const match = MatchControlState(
      id: 'match-1',
      name: 'Green FC vs White FC',
      selectedHalf: MatchHalf.first,
      status: MatchStatus.firstHalf,
      createdAtMillis: 1000,
      updatedAtMillis: 1000,
      elapsedSeconds: 60,
      clockStartedAtMillis: 1000,
    );

    const events = [
      MatchEvent(
        id: 'event-1',
        matchId: 'match-1',
        type: MatchEventType.goal,
        teamName: 'Green FC',
        minute: 8,
        createdAtMillis: 2000,
        teamSide: TeamSide.home,
      ),
      MatchEvent(
        id: 'event-2',
        matchId: 'match-1',
        type: MatchEventType.yellowCard,
        teamName: 'White FC',
        minute: 12,
        createdAtMillis: 3000,
        teamSide: TeamSide.away,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MatchDashboardView(
              canWrite: true,
              matchesState: AsyncData([match]),
              allEventsState: AsyncData(events),
              presenceState: AsyncData(
                DittoPresenceSummary(
                  localPeerName: 'Test peer',
                  remotePeerCount: 2,
                  connectedToDittoServer: true,
                ),
              ),
              selectedMatchId: 'match-1',
              onMatchSelected: _noopString,
              onCreateMatch: _noop,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('TEAM TIMELINE'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Yellow card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

void _noopString(String value) {}
