import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/match_events/match_events_screen.dart';

class MatchTrackerApp extends ConsumerWidget {
  const MatchTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Local-First Match Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MatchEventsScreen(),
    );
  }
}

// Ditto setup lives in this file
