import 'app_role.dart';

class MatchParticipant {
  const MatchParticipant({
    required this.id,
    required this.matchId,
    required this.role,
    required this.deviceName,
    required this.lastSeenMillis,
  });

  final String id;
  final String matchId;
  final AppRole role;
  final String deviceName;
  final int lastSeenMillis;

  factory MatchParticipant.fromJson(Map<String, dynamic> json) {
    return MatchParticipant(
      id: json['_id']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      role: _roleFromName(json['role']?.toString()),
      deviceName: json['deviceName']?.toString() ?? 'Unknown device',
      lastSeenMillis: _readInt(json['lastSeenMillis']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'matchId': matchId,
      'role': role.name,
      'deviceName': deviceName,
      'lastSeenMillis': lastSeenMillis,
    };
  }
}

AppRole _roleFromName(String? name) {
  for (final role in AppRole.values) {
    if (role.name == name) return role;
  }
  return AppRole.spectator;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
