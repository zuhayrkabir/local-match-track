import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_tracker_theme.dart';
import 'providers.dart';
import '../features/match_events/match_events_screen.dart';

class MatchTrackerApp extends ConsumerWidget {
  const MatchTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Local-First Match Tracker',
      theme: MatchTrackerTheme.light,
      darkTheme: MatchTrackerTheme.dark,
      themeMode: themeMode,
      home: const MatchEventsScreen(),
    );
  }
}

// Ditto setup lives in this file
