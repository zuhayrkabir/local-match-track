import 'package:flutter/material.dart';

import '../features/match_events/match_events_screen.dart';
import 'match_tracker_theme.dart';

class MatchTrackerApp extends StatelessWidget {
  const MatchTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local-First Match Tracker',
      theme: MatchTrackerTheme.theme,
      home: const MatchEventsScreen(),
    );
  }
}

// Ditto setup lives in this file
