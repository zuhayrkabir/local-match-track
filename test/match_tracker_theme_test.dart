import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_first_match_tracker/app/match_tracker_theme.dart';
import 'package:local_first_match_tracker/design/match_center_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('defines a single broadcast dark football theme', () {
    final theme = MatchTrackerTheme.theme;

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, MatchCenterColors.pitchBlack);
    expect(theme.colorScheme.primary, MatchCenterColors.lime);
  });
}
