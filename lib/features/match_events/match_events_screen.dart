import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/match_event.dart';
import '../../ditto/ditto_manager.dart';

class MatchEventsScreen extends ConsumerWidget {
  const MatchEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerState = ref.watch(dittoManagerProvider);
    final eventsState = ref.watch(matchEventsProvider);
    final presenceState = ref.watch(dittoPresenceSummaryProvider);
    final canAddGoal = managerState.valueOrNull?.dataAccessReady ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local-First Match Tracker'),
        actions: const [_ThemeModeButton()],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MatchHero(eventsState: eventsState),
            const SizedBox(height: 16),
            _DittoStatusCard(
              managerState: managerState,
              presenceState: presenceState,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canAddGoal ? () => _addGoal(context, ref) : null,
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Add test goal'),
            ),
            const SizedBox(height: 16),
            Text(
              'Match timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: eventsState.when(
                data: (events) => _EventList(events: events),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorText(error: error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.addTestGoal();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not add goal: $error')));
    }
  }
}

class _ThemeModeButton extends ConsumerWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final nextMode = switch (mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };

    return IconButton(
      tooltip: 'Change theme',
      onPressed: () {
        ref.read(themeModeProvider.notifier).state = nextMode;
      },
      icon: Icon(icon),
    );
  }
}

class _MatchHero extends StatelessWidget {
  const _MatchHero({required this.eventsState});

  final AsyncValue<List<MatchEvent>> eventsState;

  @override
  Widget build(BuildContext context) {
    final events = eventsState.valueOrNull ?? const <MatchEvent>[];
    final greenGoals = events
        .where(
          (event) =>
              event.type == MatchEventType.goal && event.teamName == 'Green FC',
        )
        .length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const Spacer(),
                Text(
                  'LIVE DEMO',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Green FC',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$greenGoals - 0',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Score is derived from synced goal events.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DittoStatusCard extends StatelessWidget {
  const _DittoStatusCard({
    required this.managerState,
    required this.presenceState,
  });

  final AsyncValue<DittoManager> managerState;
  final AsyncValue<DittoPresenceSummary> presenceState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ditto 5.1 status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            managerState.when(
              data: (manager) => Text(
                '${manager.modeLabel}\n'
                '${manager.activationMessage}',
              ),
              loading: () => const Text('Opening Ditto...'),
              error: (error, _) => _ErrorText(error: error),
            ),
            const SizedBox(height: 8),
            presenceState.when(
              data: (summary) => Text(
                'Device: ${summary.localPeerName}\n'
                'Remote peers visible: ${summary.remotePeerCount}\n'
                'Connected to Ditto Server: ${summary.connectedToDittoServer}',
              ),
              loading: () => const Text('Waiting for presence graph...'),
              error: (error, _) => _ErrorText(error: error),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events});

  final List<MatchEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stadium,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No events yet. Tap “Add test goal” to kick things off.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: const Icon(Icons.sports_soccer),
            ),
            title: Text('${event.label} — ${event.teamName}'),
            subtitle: Text('Minute ${event.minute} • ${event.id}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      error.toString(),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
