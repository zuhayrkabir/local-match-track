import '../domain/match_event.dart';
import '../domain/app_role.dart';
import '../domain/match_control.dart';
import '../domain/match_review_proposal.dart';
import '../domain/player.dart';

abstract interface class MatchEventRepository {
  Stream<List<MatchControlState>> watchMatches();

  Stream<MatchControlState> watchMatchControl();

  Stream<List<MatchEvent>> watchEvents();

  Stream<List<MatchEvent>> watchAllEvents();

  Stream<List<MatchReviewProposal>> watchPendingReviewProposals();

  Stream<bool> watchRefereeOnline();

  Future<MatchControlState> createMatch();

  Future<void> deleteMatch(String matchId);

  Future<void> renameMatch({required String matchId, required String name});

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

  Future<void> proposeReview({
    required MatchEventType type,
    required TeamSide teamSide,
    DemoPlayer? player,
  });

  Future<void> acceptReviewProposal(MatchReviewProposal proposal);

  Future<void> rejectReviewProposal(MatchReviewProposal proposal);

  Future<void> publishParticipantHeartbeat(AppRole role);
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
  Stream<List<MatchReviewProposal>> watchPendingReviewProposals() {
    return Stream.value(const []);
  }

  @override
  Stream<bool> watchRefereeOnline() {
    return Stream.value(false);
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
  Future<void> renameMatch({required String matchId, required String name}) {
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

  @override
  Future<void> proposeReview({
    required MatchEventType type,
    required TeamSide teamSide,
    DemoPlayer? player,
  }) {
    throw StateError(reason);
  }

  @override
  Future<void> acceptReviewProposal(MatchReviewProposal proposal) {
    throw StateError(reason);
  }

  @override
  Future<void> rejectReviewProposal(MatchReviewProposal proposal) {
    throw StateError(reason);
  }

  @override
  Future<void> publishParticipantHeartbeat(AppRole role) {
    throw StateError(reason);
  }
}
