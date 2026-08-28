import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runApp(const ProviderScope(child: MatchTrackerApp()));
}

// Flutter starts the app
// Riverpod starts the provider system
// The app widget draws the UI
