enum MatchEventType { goal, yellowCard, redCard, substitution, foul, note }

class MatchEvent {
  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    required this.teamName,
    required this.minute,
    required this.createdAtMillis,
  });

  final String id;
  final String matchId;
  final MatchEventType type;
  final String teamName;
  final int minute;
  final int createdAtMillis;

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['_id'].toString(),
      matchId: json['matchId'].toString(),
      type: MatchEventType.values.byName(json['type'].toString()),
      teamName: json['teamName'].toString(),
      minute: json['minute'] as int,
      createdAtMillis: json['createdAtMillis'] as int,
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
    };
  }

  String get label {
    return switch (type) {
      MatchEventType.goal => 'Goal',
      MatchEventType.yellowCard => 'Yellow card',
      MatchEventType.redCard => 'Red card',
      MatchEventType.substitution => 'Substitution',
      MatchEventType.foul => 'Foul',
      MatchEventType.note => 'Note',
    };
  }
}
