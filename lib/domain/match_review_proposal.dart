import 'match_event.dart';
import 'player.dart';

enum MatchReviewProposalStatus { pending, accepted, rejected }

class MatchReviewProposal {
  const MatchReviewProposal({
    required this.id,
    required this.matchId,
    required this.type,
    required this.teamSide,
    required this.teamName,
    required this.minute,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    required this.status,
    this.playerId,
    this.playerName,
    this.playerNumber,
    this.proposedBy = 'Assistant referee',
    this.decidedAtMillis,
  });

  final String id;
  final String matchId;
  final MatchEventType type;
  final TeamSide teamSide;
  final String teamName;
  final int minute;
  final int createdAtMillis;
  final int updatedAtMillis;
  final MatchReviewProposalStatus status;
  final String? playerId;
  final String? playerName;
  final int? playerNumber;
  final String proposedBy;
  final int? decidedAtMillis;

  factory MatchReviewProposal.fromJson(Map<String, dynamic> json) {
    return MatchReviewProposal(
      id: json['_id']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      type: _eventTypeFromName(json['type']?.toString()),
      teamSide: _teamSideFromName(json['teamSide']?.toString()),
      teamName: json['teamName']?.toString() ?? 'Unknown team',
      minute: _readInt(json['minute']),
      createdAtMillis: _readInt(json['createdAtMillis']),
      updatedAtMillis: _readInt(json['updatedAtMillis']),
      status: _statusFromName(json['status']?.toString()),
      playerId: json['playerId']?.toString(),
      playerName: json['playerName']?.toString(),
      playerNumber: _readNullableInt(json['playerNumber']),
      proposedBy: json['proposedBy']?.toString() ?? 'Assistant referee',
      decidedAtMillis: _readNullableInt(json['decidedAtMillis']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'matchId': matchId,
      'type': type.name,
      'teamSide': teamSide.name,
      'teamName': teamName,
      'minute': minute,
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis,
      'status': status.name,
      if (playerId != null) 'playerId': playerId,
      if (playerName != null) 'playerName': playerName,
      if (playerNumber != null) 'playerNumber': playerNumber,
      'proposedBy': proposedBy,
      if (decidedAtMillis != null) 'decidedAtMillis': decidedAtMillis,
    };
  }

  MatchReviewProposal copyWith({
    MatchReviewProposalStatus? status,
    int? updatedAtMillis,
    int? decidedAtMillis,
  }) {
    return MatchReviewProposal(
      id: id,
      matchId: matchId,
      type: type,
      teamSide: teamSide,
      teamName: teamName,
      minute: minute,
      createdAtMillis: createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      status: status ?? this.status,
      playerId: playerId,
      playerName: playerName,
      playerNumber: playerNumber,
      proposedBy: proposedBy,
      decidedAtMillis: decidedAtMillis ?? this.decidedAtMillis,
    );
  }

  MatchEvent toAcceptedEvent({
    required String id,
    required int createdAtMillis,
  }) {
    return MatchEvent(
      id: id,
      matchId: matchId,
      type: type,
      teamName: teamName,
      minute: minute,
      createdAtMillis: createdAtMillis,
      playerId: playerId,
      playerName: playerName,
      playerNumber: playerNumber,
      teamSide: teamSide,
    );
  }

  String get label => switch (type) {
    MatchEventType.offside => 'Offside review',
    MatchEventType.foul => 'Foul review',
    _ => 'Review',
  };

  String get subjectLabel {
    if (playerName == null || playerNumber == null) return teamName;
    return '$teamName #$playerNumber — $playerName';
  }
}

MatchEventType _eventTypeFromName(String? name) {
  for (final type in [MatchEventType.offside, MatchEventType.foul]) {
    if (type.name == name) return type;
  }
  return MatchEventType.foul;
}

TeamSide _teamSideFromName(String? name) {
  for (final side in TeamSide.values) {
    if (side.name == name) return side;
  }
  return TeamSide.home;
}

MatchReviewProposalStatus _statusFromName(String? name) {
  for (final status in MatchReviewProposalStatus.values) {
    if (status.name == name) return status;
  }
  return MatchReviewProposalStatus.pending;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
