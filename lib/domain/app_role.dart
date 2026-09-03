enum AppRole { referee, assistantReferee, spectator }

extension AppRoleLabels on AppRole {
  String get label {
    return switch (this) {
      AppRole.referee => 'Referee',
      AppRole.assistantReferee => 'Assistant Referee',
      AppRole.spectator => 'Spectator',
    };
  }

  String get description {
    return switch (this) {
      AppRole.referee => 'Control the match and log official events.',
      AppRole.assistantReferee =>
        'Suggest offside or foul calls for the referee to review.',
      AppRole.spectator => 'View the score, clock, match list, and timeline.',
    };
  }

  bool get canWriteMatch {
    return switch (this) {
      AppRole.referee => true,
      AppRole.assistantReferee => false,
      AppRole.spectator => false,
    };
  }

  bool get canProposeReviews {
    return switch (this) {
      AppRole.referee => false,
      AppRole.assistantReferee => true,
      AppRole.spectator => false,
    };
  }

  bool get canReviewProposals {
    return switch (this) {
      AppRole.referee => true,
      AppRole.assistantReferee => false,
      AppRole.spectator => false,
    };
  }
}
