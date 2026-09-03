enum MatchHalf { first, second }

enum MatchStatus { notStarted, firstHalf, halftime, secondHalf, fullTime }

class MatchControlState {
  const MatchControlState({
    required this.id,
    required this.name,
    required this.selectedHalf,
    required this.status,
    required this.createdAtMillis,
    required this.updatedAtMillis,
    required this.elapsedSeconds,
    this.clockStartedAtMillis,
  });

  static const demoMatchId = 'demo-match';

  factory MatchControlState.initial({String id = demoMatchId, String? name}) {
    return MatchControlState(
      id: id,
      name: name ?? 'Demo match',
      selectedHalf: MatchHalf.first,
      status: MatchStatus.notStarted,
      createdAtMillis: 0,
      updatedAtMillis: 0,
      elapsedSeconds: 0,
    );
  }

  factory MatchControlState.fromJson(Map<String, dynamic> json) {
    return MatchControlState(
      id: json['_id']?.toString() ?? demoMatchId,
      name: json['name']?.toString() ?? 'Untitled match',
      selectedHalf: _enumByName(
        MatchHalf.values,
        json['selectedHalf']?.toString(),
        MatchHalf.first,
      ),
      status: _enumByName(
        MatchStatus.values,
        json['status']?.toString(),
        MatchStatus.notStarted,
      ),
      createdAtMillis: _readInt(json['createdAtMillis']),
      updatedAtMillis: _readInt(json['updatedAtMillis']),
      elapsedSeconds: _readInt(json['elapsedSeconds']),
      clockStartedAtMillis: _readNullableInt(json['clockStartedAtMillis']),
    );
  }

  final String id;
  final String name;
  final MatchHalf selectedHalf;
  final MatchStatus status;
  final int createdAtMillis;
  final int updatedAtMillis;
  final int elapsedSeconds;
  final int? clockStartedAtMillis;

  MatchControlState copyWith({
    String? name,
    MatchHalf? selectedHalf,
    MatchStatus? status,
    int? createdAtMillis,
    int? updatedAtMillis,
    int? elapsedSeconds,
    int? clockStartedAtMillis,
    bool clearClockStartedAt = false,
  }) {
    return MatchControlState(
      id: id,
      name: name ?? this.name,
      selectedHalf: selectedHalf ?? this.selectedHalf,
      status: status ?? this.status,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      clockStartedAtMillis: clearClockStartedAt
          ? null
          : clockStartedAtMillis ?? this.clockStartedAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'selectedHalf': selectedHalf.name,
      'status': status.name,
      'createdAtMillis': createdAtMillis,
      'updatedAtMillis': updatedAtMillis,
      'elapsedSeconds': elapsedSeconds,
      if (clockStartedAtMillis != null)
        'clockStartedAtMillis': clockStartedAtMillis,
    };
  }

  String get selectedHalfLabel {
    return switch (selectedHalf) {
      MatchHalf.first => 'First half',
      MatchHalf.second => 'Second half',
    };
  }

  String get statusLabel {
    return switch (status) {
      MatchStatus.notStarted => 'Not started',
      MatchStatus.firstHalf => 'First half live',
      MatchStatus.halftime => 'Halftime',
      MatchStatus.secondHalf => 'Second half live',
      MatchStatus.fullTime => 'Full time',
    };
  }

  bool get isHalfRunning {
    return status == MatchStatus.firstHalf || status == MatchStatus.secondHalf;
  }

  int elapsedSecondsAt(int nowMillis) {
    final startedAt = clockStartedAtMillis;
    if (!isHalfRunning || startedAt == null) {
      return elapsedSeconds;
    }

    final deltaSeconds = ((nowMillis - startedAt) / 1000).floor();
    return elapsedSeconds + deltaSeconds.clamp(0, 24 * 60 * 60);
  }

  int matchMinuteAt(int nowMillis) {
    final elapsed = elapsedSecondsAt(nowMillis);
    if (elapsed <= 0 && !isHalfRunning) {
      return 0;
    }

    final halfOffset = selectedHalf == MatchHalf.second ? 45 : 0;
    return halfOffset + (elapsed ~/ 60) + 1;
  }

  String clockLabelAt(int nowMillis) {
    final elapsed = elapsedSecondsAt(nowMillis);
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
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
