import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/app_role.dart';

void main() {
  test(
    'role permissions separate referee, assistant, and spectator workflows',
    () {
      expect(AppRole.referee.canWriteMatch, isTrue);
      expect(AppRole.referee.canReviewProposals, isTrue);
      expect(AppRole.referee.canProposeReviews, isFalse);

      expect(AppRole.assistantReferee.canWriteMatch, isFalse);
      expect(AppRole.assistantReferee.canReviewProposals, isFalse);
      expect(AppRole.assistantReferee.canProposeReviews, isTrue);

      expect(AppRole.spectator.canWriteMatch, isFalse);
      expect(AppRole.spectator.canReviewProposals, isFalse);
      expect(AppRole.spectator.canProposeReviews, isFalse);
    },
  );
}
