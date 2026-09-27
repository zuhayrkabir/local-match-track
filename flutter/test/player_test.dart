import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/domain/player.dart';

void main() {
  test('demo roster has 18 players and 7 bench players per team', () {
    for (final side in TeamSide.values) {
      expect(demoPlayersForSide(side), hasLength(18));
      expect(demoStartersForSide(side), hasLength(11));
      expect(demoBenchPlayersForSide(side), hasLength(7));
    }
  });
}
