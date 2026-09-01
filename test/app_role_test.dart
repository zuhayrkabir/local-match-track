import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/app_role.dart';

void main() {
  test('referee can write while spectator can only view', () {
    expect(AppRole.referee.canWriteMatch, isTrue);
    expect(AppRole.spectator.canWriteMatch, isFalse);
  });
}
