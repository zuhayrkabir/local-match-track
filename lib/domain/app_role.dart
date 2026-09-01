enum AppRole { referee, spectator }

extension AppRoleLabels on AppRole {
  String get label {
    return switch (this) {
      AppRole.referee => 'Referee',
      AppRole.spectator => 'Spectator',
    };
  }

  String get description {
    return switch (this) {
      AppRole.referee => 'Control the match and log official events.',
      AppRole.spectator => 'View the score, clock, match list, and timeline.',
    };
  }

  bool get canWriteMatch {
    return switch (this) {
      AppRole.referee => true,
      AppRole.spectator => false,
    };
  }
}
