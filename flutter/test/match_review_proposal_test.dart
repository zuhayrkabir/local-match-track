import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/match_event.dart';
import 'package:local_first_match_tracker/domain/match_review_proposal.dart';
import 'package:local_first_match_tracker/domain/player.dart';

void main() {
  test('serializes and deserializes pending assistant review proposal', () {
    const proposal = MatchReviewProposal(
      id: 'review-1',
      matchId: 'match-1',
      type: MatchEventType.offside,
      teamSide: TeamSide.away,
      teamName: 'White FC',
      minute: 23,
      createdAtMillis: 1000,
      updatedAtMillis: 1000,
      status: MatchReviewProposalStatus.pending,
      playerId: 'away-9',
      playerName: 'P. Wright',
      playerNumber: 9,
    );

    final restored = MatchReviewProposal.fromJson(proposal.toJson());

    expect(restored.id, 'review-1');
    expect(restored.matchId, 'match-1');
    expect(restored.type, MatchEventType.offside);
    expect(restored.teamSide, TeamSide.away);
    expect(restored.status, MatchReviewProposalStatus.pending);
    expect(restored.subjectLabel, 'White FC #9 — P. Wright');
  });

  test('accepted proposal converts into an official event', () {
    const proposal = MatchReviewProposal(
      id: 'review-1',
      matchId: 'match-1',
      type: MatchEventType.foul,
      teamSide: TeamSide.home,
      teamName: 'Green FC',
      minute: 12,
      createdAtMillis: 1000,
      updatedAtMillis: 1000,
      status: MatchReviewProposalStatus.pending,
      playerId: 'home-7',
      playerName: 'A. Khan',
      playerNumber: 7,
    );

    final event = proposal.toAcceptedEvent(
      id: 'event-1',
      createdAtMillis: 2000,
    );

    expect(event.id, 'event-1');
    expect(event.matchId, 'match-1');
    expect(event.type, MatchEventType.foul);
    expect(event.teamSide, TeamSide.home);
    expect(event.playerName, 'A. Khan');
    expect(event.minute, 12);
  });
}
