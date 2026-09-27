import 'player.dart';

enum MatchEventType {
  halfStarted,
  halfEnded,
  goal,
  yellowCard,
  redCard,
  offside,
  substitution,
  foul,
  note,
}

class MatchEvent {
  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    required this.teamName,
    required this.minute,
    required this.createdAtMillis,
    this.playerId,
    this.playerName,
    this.playerNumber,
    this.substitutePlayerId,
    this.substitutePlayerName,
    this.substitutePlayerNumber,
    this.teamSide,
  });

  final String id;
  final String matchId;
  final MatchEventType type;
  final String teamName;
  final int minute;
  final int createdAtMillis;
  final String? playerId;
  final String? playerName;
  final int? playerNumber;
  final String? substitutePlayerId;
  final String? substitutePlayerName;
  final int? substitutePlayerNumber;
  final TeamSide? teamSide;

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['_id']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      type: _eventTypeFromName(json['type']?.toString()),
      teamName: json['teamName']?.toString() ?? 'Unknown team',
      minute: _readInt(json['minute']),
      createdAtMillis: _readInt(json['createdAtMillis']),
      playerId: json['playerId']?.toString(),
      playerName: json['playerName']?.toString(),
      playerNumber: _readNullableInt(json['playerNumber']),
      substitutePlayerId: json['substitutePlayerId']?.toString(),
      substitutePlayerName: json['substitutePlayerName']?.toString(),
      substitutePlayerNumber: _readNullableInt(json['substitutePlayerNumber']),
      teamSide: _teamSideFromName(json['teamSide']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'matchId': matchId,
      'type': type.name,
      'teamName': teamName,
      'minute': minute,
      'createdAtMillis': createdAtMillis,
      if (playerId != null) 'playerId': playerId,
      if (playerName != null) 'playerName': playerName,
      if (playerNumber != null) 'playerNumber': playerNumber,
      if (substitutePlayerId != null) 'substitutePlayerId': substitutePlayerId,
      if (substitutePlayerName != null)
        'substitutePlayerName': substitutePlayerName,
      if (substitutePlayerNumber != null)
        'substitutePlayerNumber': substitutePlayerNumber,
      if (teamSide != null) 'teamSide': teamSide!.name,
    };
  }

  String get label {
    return switch (type) {
      MatchEventType.halfStarted => 'Half started',
      MatchEventType.halfEnded => 'Half ended',
      MatchEventType.goal => 'Goal',
      MatchEventType.yellowCard => 'Yellow card',
      MatchEventType.redCard => 'Red card',
      MatchEventType.offside => 'Offside',
      MatchEventType.substitution => 'Substitution',
      MatchEventType.foul => 'Foul',
      MatchEventType.note => 'Note',
    };
  }

  String get subjectLabel {
    if (type == MatchEventType.substitution &&
        playerName != null &&
        playerNumber != null &&
        substitutePlayerName != null &&
        substitutePlayerNumber != null) {
      return '$teamName #$substitutePlayerNumber — $substitutePlayerName on, '
          '#$playerNumber — $playerName off';
    }

    if (playerName == null || playerNumber == null) {
      return teamName;
    }
    return '$teamName #$playerNumber — $playerName';
  }
}

MatchEventType _eventTypeFromName(String? name) {
  for (final type in MatchEventType.values) {
    if (type.name == name) return type;
  }
  return MatchEventType.note;
}

TeamSide? _teamSideFromName(String? name) {
  for (final side in TeamSide.values) {
    if (side.name == name) return side;
  }
  return null;
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
