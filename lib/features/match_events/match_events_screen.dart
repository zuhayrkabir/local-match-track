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
      appBar: AppBar(title: const Text('Local-First Match Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
      return const Center(
        child: Text('No events yet. Tap “Add test goal” to create one.'),
      );
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          leading: const Icon(Icons.sports_soccer),
          title: Text('${event.label} — ${event.teamName}'),
          subtitle: Text('Minute ${event.minute} • ${event.id}'),
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
