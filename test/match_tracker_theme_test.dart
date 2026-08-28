import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_first_match_tracker/app/match_tracker_theme.dart';

void main() {
  test('defines separate light and dark football themes', () {
    expect(MatchTrackerTheme.light.brightness, Brightness.light);
    expect(MatchTrackerTheme.dark.brightness, Brightness.dark);
    expect(
      MatchTrackerTheme.light.colorScheme.primary,
      isNot(MatchTrackerTheme.dark.colorScheme.primary),
    );
  });
}
