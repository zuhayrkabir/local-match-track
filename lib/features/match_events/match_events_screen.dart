import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/match_center_tokens.dart';
import '../../domain/app_role.dart';
import '../../domain/match_control.dart';
import '../../domain/match_event.dart';
import '../../domain/player.dart';
import '../../ditto/ditto_manager.dart';
import '../ditto_tools/ditto_tools_entry.dart';
import '../match_dashboard/match_dashboard_view.dart';

class MatchEventsScreen extends ConsumerStatefulWidget {
  const MatchEventsScreen({super.key});

  @override
  ConsumerState<MatchEventsScreen> createState() => _MatchEventsScreenState();
}

class _MatchEventsScreenState extends ConsumerState<MatchEventsScreen> {
  MatchEventType _selectedEventType = MatchEventType.goal;
  TeamSide _selectedTeamSide = TeamSide.home;
  DemoPlayer _selectedPlayer = demoPlayers.first;
  TeamSide _selectedSubstitutionTeamSide = TeamSide.home;
  DemoPlayer _selectedPlayerOut = demoStartersForSide(TeamSide.home).first;
  DemoPlayer _selectedPlayerIn = demoBenchPlayersForSide(TeamSide.home).first;

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(selectedRoleProvider);
    final managerState = ref.watch(dittoManagerProvider);
    final matchesState = ref.watch(matchesProvider);
    final matchControlState = ref.watch(matchControlProvider);
    final eventsState = ref.watch(matchEventsProvider);
    final allEventsState = ref.watch(allMatchEventsProvider);
    final presenceState = ref.watch(dittoPresenceSummaryProvider);
    final showDashboard = ref.watch(showDashboardProvider);
    final canWrite =
        (managerState.valueOrNull?.dataAccessReady ?? false) &&
        (selectedRole?.canWriteMatch ?? false);

    if (selectedRole == null) {
      return _RoleSelectionScreen(
        onRoleSelected: (role) {
          ref.read(selectedRoleProvider.notifier).state = role;
        },
      );
    }

    final compactAppBar = MediaQuery.sizeOf(context).width < 520;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          compactAppBar ? 'Match Tracker' : 'Local-First Match Tracker',
        ),
        actions: [
          _RoleBadge(role: selectedRole, compact: compactAppBar),
          DittoToolsIconButton(manager: managerState.valueOrNull),
          IconButton(
            tooltip: 'Change role',
            onPressed: () {
              ref.read(selectedRoleProvider.notifier).state = null;
            },
            icon: const Icon(Icons.switch_account),
          ),
          const _ThemeModeButton(),
        ],
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
        child: ListView(
          children: [
            _ViewSwitcher(
              showDashboard: showDashboard,
              onViewChanged: (value) {
                ref.read(showDashboardProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            if (showDashboard)
              MatchDashboardView(
                canWrite: canWrite,
                matchesState: matchesState,
                allEventsState: allEventsState,
                presenceState: presenceState,
                selectedMatchId: ref.watch(selectedMatchIdProvider),
                onMatchSelected: (matchId) {
                  ref.read(selectedMatchIdProvider.notifier).state = matchId;
                  ref.read(showDashboardProvider.notifier).state = false;
                },
                onCreateMatch: _createMatch,
              )
            else ...[
              _DittoStatusCard(
                managerState: managerState,
                presenceState: presenceState,
              ),
              const SizedBox(height: 16),
              _MatchHero(
                eventsState: eventsState,
                matchControlState: matchControlState,
              ),
              const SizedBox(height: 16),
              _MatchSessionCard(
                canWrite: canWrite,
                matchesState: matchesState,
                selectedMatchId: ref.watch(selectedMatchIdProvider),
                onMatchSelected: (matchId) {
                  if (matchId == null) return;
                  ref.read(selectedMatchIdProvider.notifier).state = matchId;
                },
                onCreateMatch: _createMatch,
                onDeleteMatch: _deleteSelectedMatch,
              ),
              const SizedBox(height: 16),
              if (selectedRole.canWriteMatch) ...[
                _MatchControlCard(
                  canWrite: canWrite,
                  matchControlState: matchControlState,
                  onSelectHalf: _selectHalf,
                  onStartHalf: _startSelectedHalf,
                  onEndHalf: _endCurrentHalf,
                ),
                const SizedBox(height: 16),
                _OfficialEventCard(
                  canWrite: canWrite,
                  selectedEventType: _selectedEventType,
                  selectedTeamSide: _selectedTeamSide,
                  selectedPlayer: _selectedPlayer,
                  onEventTypeChanged: (type) {
                    if (type == null) return;
                    setState(() => _selectedEventType = type);
                  },
                  onTeamChanged: (teamSide) {
                    if (teamSide == null) return;
                    setState(() {
                      _selectedTeamSide = teamSide;
                      _selectedPlayer = demoPlayersForSide(teamSide).first;
                    });
                  },
                  onPlayerChanged: (player) {
                    if (player == null) return;
                    setState(() => _selectedPlayer = player);
                  },
                  onLogEvent: _logOfficialEvent,
                ),
                const SizedBox(height: 16),
                _SubstitutionCard(
                  canWrite: canWrite,
                  selectedTeamSide: _selectedSubstitutionTeamSide,
                  selectedPlayerOut: _selectedPlayerOut,
                  selectedPlayerIn: _selectedPlayerIn,
                  onTeamChanged: (teamSide) {
                    if (teamSide == null) return;
                    setState(() {
                      _selectedSubstitutionTeamSide = teamSide;
                      _selectedPlayerOut = demoStartersForSide(teamSide).first;
                      _selectedPlayerIn = demoBenchPlayersForSide(teamSide)
                          .first;
                    });
                  },
                  onPlayerOutChanged: (player) {
                    if (player == null) return;
                    setState(() => _selectedPlayerOut = player);
                  },
                  onPlayerInChanged: (player) {
                    if (player == null) return;
                    setState(() => _selectedPlayerIn = player);
                  },
                  onLogSubstitution: _logSubstitution,
                ),
              ] else
                const _SpectatorNotice(),
              const SizedBox(height: 16),
              const _RosterCard(),
              const SizedBox(height: 16),
              Text(
                'Match timeline',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              eventsState.when(
                data: (events) => _EventList(events: events),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorText(error: error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectHalf(MatchHalf half) async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.selectHalf(half);
    } catch (error) {
      _showSnackBar('Could not select half: $error');
    }
  }

  Future<void> _createMatch() async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      final match = await repository.createMatch();
      ref.read(selectedMatchIdProvider.notifier).state = match.id;
    } catch (error) {
      _showSnackBar('Could not create match: $error');
    }
  }

  Future<void> _deleteSelectedMatch() async {
    final selectedMatchId = ref.read(selectedMatchIdProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete this match?'),
          content: const Text(
            'This removes the selected match and its timeline events from Ditto '
            'for every synced device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final repository = await ref.read(matchEventRepositoryProvider.future);
    final knownMatches = ref.read(matchesProvider).valueOrNull ?? const [];
    String? nextMatchId;
    for (final match in knownMatches) {
      if (match.id != selectedMatchId) {
        nextMatchId = match.id;
        break;
      }
    }

    try {
      await repository.deleteMatch(selectedMatchId);
      ref.read(selectedMatchIdProvider.notifier).state =
          nextMatchId ?? MatchControlState.demoMatchId;
    } catch (error) {
      _showSnackBar('Could not delete match: $error');
    }
  }

  Future<void> _startSelectedHalf() async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.startSelectedHalf();
    } catch (error) {
      _showSnackBar('Could not start half: $error');
    }
  }

  Future<void> _endCurrentHalf() async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.endCurrentHalf();
    } catch (error) {
      _showSnackBar('Could not end half: $error');
    }
  }

  Future<void> _logOfficialEvent() async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.addOfficialEvent(
        type: _selectedEventType,
        teamSide: _selectedTeamSide,
        player: _selectedPlayer,
      );
    } catch (error) {
      _showSnackBar('Could not log event: $error');
    }
  }

  Future<void> _logSubstitution() async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.addSubstitution(
        teamSide: _selectedSubstitutionTeamSide,
        playerOut: _selectedPlayerOut,
        playerIn: _selectedPlayerIn,
      );
    } catch (error) {
      _showSnackBar('Could not log substitution: $error');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RoleSelectionScreen extends StatelessWidget {
  const _RoleSelectionScreen({required this.onRoleSelected});

  final ValueChanged<AppRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose match role'),
        actions: const [_ThemeModeButton()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF233513), MatchCenterColors.pitchBlack],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.4,
                  colors: [
                    MatchCenterColors.featuredTop,
                    MatchCenterColors.panel,
                    MatchCenterColors.pitchBlack,
                  ],
                ),
                border: Border.all(color: MatchCenterColors.borderBright),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 26,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      color: MatchCenterColors.lime,
                      size: 44,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How are you joining this match?',
                      style: MatchCenterTypography.display(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This choice controls what this device is allowed to do. '
                      'Ditto still syncs the match data underneath.',
                      style: MatchCenterTypography.body(
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final role in AppRole.values) ...[
              _RoleOptionCard(role: role, onTap: () => onRoleSelected(role)),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({required this.role, required this.onTap});

  final AppRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        hoverColor: MatchCenterColors.lime.withValues(alpha: 0.06),
        focusColor: MatchCenterColors.lime.withValues(alpha: 0.10),
        splashColor: MatchCenterColors.lime.withValues(alpha: 0.16),
        child: Container(
          decoration: BoxDecoration(
            color: MatchCenterColors.panel,
            border: Border.all(color: MatchCenterColors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: MatchCenterColors.lime.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == AppRole.referee ? Icons.sports : Icons.visibility,
                  color: MatchCenterColors.lime,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: MatchCenterTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.description,
                      style: MatchCenterTypography.body(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right,
                color: MatchCenterColors.offWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.compact});

  final AppRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(
            role == AppRole.referee ? Icons.sports : Icons.visibility,
            size: 18,
          ),
          label: compact ? const SizedBox.shrink() : Text(role.label),
        ),
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({
    required this.showDashboard,
    required this.onViewChanged,
  });

  final bool showDashboard;
  final ValueChanged<bool> onViewChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        ButtonSegment(
          value: false,
          icon: Icon(Icons.sports_soccer),
          label: Text('Match detail'),
        ),
      ],
      selected: {showDashboard},
      onSelectionChanged: (selection) => onViewChanged(selection.first),
    );
  }
}

class _MatchSessionCard extends StatelessWidget {
  const _MatchSessionCard({
    required this.canWrite,
    required this.matchesState,
    required this.selectedMatchId,
    required this.onMatchSelected,
    required this.onCreateMatch,
    required this.onDeleteMatch,
  });

  final bool canWrite;
  final AsyncValue<List<MatchControlState>> matchesState;
  final String selectedMatchId;
  final ValueChanged<String?> onMatchSelected;
  final VoidCallback onCreateMatch;
  final VoidCallback onDeleteMatch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Match session',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            matchesState.when(
              data: (matches) {
                final visibleMatches = _ensureSelectedMatchExists(matches);
                return DropdownButtonFormField<String>(
                  initialValue:
                      visibleMatches.any((match) => match.id == selectedMatchId)
                      ? selectedMatchId
                      : visibleMatches.first.id,
                  decoration: const InputDecoration(labelText: 'Current match'),
                  items: [
                    for (final match in visibleMatches)
                      DropdownMenuItem(
                        value: match.id,
                        child: Text('${match.name} • ${match.statusLabel}'),
                      ),
                  ],
                  onChanged: onMatchSelected,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _ErrorText(error: error),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: canWrite ? onCreateMatch : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Create new match'),
                ),
                OutlinedButton.icon(
                  onPressed: canWrite ? onDeleteMatch : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete current match'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<MatchControlState> _ensureSelectedMatchExists(
    List<MatchControlState> matches,
  ) {
    if (matches.any((match) => match.id == selectedMatchId)) {
      return matches;
    }
    return [MatchControlState.initial(id: selectedMatchId), ...matches];
  }
}

class _SpectatorNotice extends StatelessWidget {
  const _SpectatorNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.visibility,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Spectator mode: this device can view the live score, clock, '
                'match session, roster, and timeline, but cannot change the match.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
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
  const _MatchHero({
    required this.eventsState,
    required this.matchControlState,
  });

  final AsyncValue<List<MatchEvent>> eventsState;
  final AsyncValue<MatchControlState> matchControlState;

  @override
  Widget build(BuildContext context) {
    final events = eventsState.valueOrNull ?? const <MatchEvent>[];
    final greenGoals = _goalsFor(events, TeamSide.home);
    final whiteGoals = _goalsFor(events, TeamSide.away);
    final matchControl = matchControlState.valueOrNull;
    final status = matchControl?.statusLabel ?? 'Waiting for match state';

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
              'Green FC vs White FC',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$greenGoals - $whiteGoals',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '$status • Score is derived from synced goal events.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
            ),
            if (matchControl != null) ...[
              const SizedBox(height: 16),
              _MatchClockPill(matchControl: matchControl),
            ],
          ],
        ),
      ),
    );
  }

  int _goalsFor(List<MatchEvent> events, TeamSide side) {
    return events
        .where(
          (event) =>
              event.type == MatchEventType.goal &&
              (event.teamSide == side ||
                  event.teamName == teamNameForSide(side)),
        )
        .length;
  }
}

class _MatchClockPill extends StatelessWidget {
  const _MatchClockPill({required this.matchControl});

  final MatchControlState matchControl;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now().millisecondsSinceEpoch,
      ),
      initialData: DateTime.now().millisecondsSinceEpoch,
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now().millisecondsSinceEpoch;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                matchControl.isHalfRunning ? Icons.timer : Icons.timer_off,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${matchControl.clockLabelAt(now)}'
                ' • Match minute ${matchControl.matchMinuteAt(now)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MatchControlCard extends StatelessWidget {
  const _MatchControlCard({
    required this.canWrite,
    required this.matchControlState,
    required this.onSelectHalf,
    required this.onStartHalf,
    required this.onEndHalf,
  });

  final bool canWrite;
  final AsyncValue<MatchControlState> matchControlState;
  final ValueChanged<MatchHalf> onSelectHalf;
  final VoidCallback onStartHalf;
  final VoidCallback onEndHalf;

  @override
  Widget build(BuildContext context) {
    final state = matchControlState.valueOrNull ?? MatchControlState.initial();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Main referee controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Current state: ${state.statusLabel}'),
            const SizedBox(height: 12),
            SegmentedButton<MatchHalf>(
              segments: const [
                ButtonSegment(
                  value: MatchHalf.first,
                  label: Text('First half'),
                  icon: Icon(Icons.looks_one),
                ),
                ButtonSegment(
                  value: MatchHalf.second,
                  label: Text('Second half'),
                  icon: Icon(Icons.looks_two),
                ),
              ],
              selected: {state.selectedHalf},
              onSelectionChanged: canWrite
                  ? (selection) => onSelectHalf(selection.first)
                  : null,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: canWrite ? onStartHalf : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Start ${state.selectedHalfLabel}'),
                ),
                OutlinedButton.icon(
                  onPressed: canWrite ? onEndHalf : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('End half'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialEventCard extends StatelessWidget {
  const _OfficialEventCard({
    required this.canWrite,
    required this.selectedEventType,
    required this.selectedTeamSide,
    required this.selectedPlayer,
    required this.onEventTypeChanged,
    required this.onTeamChanged,
    required this.onPlayerChanged,
    required this.onLogEvent,
  });

  final bool canWrite;
  final MatchEventType selectedEventType;
  final TeamSide selectedTeamSide;
  final DemoPlayer selectedPlayer;
  final ValueChanged<MatchEventType?> onEventTypeChanged;
  final ValueChanged<TeamSide?> onTeamChanged;
  final ValueChanged<DemoPlayer?> onPlayerChanged;
  final VoidCallback onLogEvent;

  @override
  Widget build(BuildContext context) {
    const officialEventTypes = [
      MatchEventType.goal,
      MatchEventType.yellowCard,
      MatchEventType.redCard,
      MatchEventType.offside,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Log official event',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MatchEventType>(
              initialValue: selectedEventType,
              decoration: const InputDecoration(labelText: 'Event'),
              items: [
                for (final type in officialEventTypes)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: canWrite ? onEventTypeChanged : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<TeamSide>(
              segments: [
                for (final teamSide in TeamSide.values)
                  ButtonSegment(
                    value: teamSide,
                    label: Text(teamNameForSide(teamSide)),
                    icon: Icon(
                      teamSide == TeamSide.home ? Icons.shield : Icons.flag,
                    ),
                  ),
              ],
              selected: {selectedTeamSide},
              onSelectionChanged: canWrite
                  ? (selection) => onTeamChanged(selection.first)
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DemoPlayer>(
              initialValue: selectedPlayer,
              decoration: const InputDecoration(labelText: 'Player involved'),
              items: [
                for (final player in demoPlayersForSide(selectedTeamSide))
                  DropdownMenuItem(
                    value: player,
                    child: Text(player.rosterLabel),
                  ),
              ],
              onChanged: canWrite ? onPlayerChanged : null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: canWrite ? onLogEvent : null,
              icon: const Icon(Icons.add_circle),
              label: const Text('Log event'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubstitutionCard extends StatelessWidget {
  const _SubstitutionCard({
    required this.canWrite,
    required this.selectedTeamSide,
    required this.selectedPlayerOut,
    required this.selectedPlayerIn,
    required this.onTeamChanged,
    required this.onPlayerOutChanged,
    required this.onPlayerInChanged,
    required this.onLogSubstitution,
  });

  final bool canWrite;
  final TeamSide selectedTeamSide;
  final DemoPlayer selectedPlayerOut;
  final DemoPlayer selectedPlayerIn;
  final ValueChanged<TeamSide?> onTeamChanged;
  final ValueChanged<DemoPlayer?> onPlayerOutChanged;
  final ValueChanged<DemoPlayer?> onPlayerInChanged;
  final VoidCallback onLogSubstitution;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Log substitution',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<TeamSide>(
              segments: [
                for (final teamSide in TeamSide.values)
                  ButtonSegment(
                    value: teamSide,
                    label: Text(teamNameForSide(teamSide)),
                    icon: Icon(
                      teamSide == TeamSide.home ? Icons.shield : Icons.flag,
                    ),
                  ),
              ],
              selected: {selectedTeamSide},
              onSelectionChanged: canWrite
                  ? (selection) => onTeamChanged(selection.first)
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.arrow_downward, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<DemoPlayer>(
                    initialValue: selectedPlayerOut,
                    decoration: const InputDecoration(labelText: 'Player off'),
                    items: [
                      for (final player in demoStartersForSide(
                        selectedTeamSide,
                      ))
                        DropdownMenuItem(
                          value: player,
                          child: Text(player.rosterLabel),
                        ),
                    ],
                    onChanged: canWrite ? onPlayerOutChanged : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.arrow_upward, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<DemoPlayer>(
                    initialValue: selectedPlayerIn,
                    decoration: const InputDecoration(labelText: 'Player on'),
                    items: [
                      for (final player in demoBenchPlayersForSide(
                        selectedTeamSide,
                      ))
                        DropdownMenuItem(
                          value: player,
                          child: Text(player.rosterLabel),
                        ),
                    ],
                    onChanged: canWrite ? onPlayerInChanged : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: canWrite ? onLogSubstitution : null,
              icon: const Icon(Icons.swap_vert),
              label: const Text('Log substitution'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Rosters', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            for (final teamSide in TeamSide.values) ...[
              Text(
                '${teamNameForSide(teamSide)} '
                '(${demoPlayersForSide(teamSide).length} players, '
                '${demoBenchPlayersForSide(teamSide).length} bench)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final player in demoPlayersForSide(teamSide))
                    Chip(
                      avatar: Icon(
                        player.isStarter ? Icons.person : Icons.chair,
                        size: 18,
                      ),
                      label: Text(
                        '#${player.number} ${player.name}'
                        '${player.isStarter ? '' : ' • bench'}',
                      ),
                    ),
                ],
              ),
              if (teamSide != TeamSide.values.last) const Divider(height: 28),
            ],
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
            const SizedBox(height: 12),
            managerState.when(
              data: (manager) => DittoToolsButton(manager: manager),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
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
                  'No events yet. Use the referee controls to kick things off.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final event in events)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
                child: Icon(_iconFor(event.type)),
              ),
              title: Text('${event.label} — ${event.subjectLabel}'),
              subtitle: Text(_subtitleFor(event)),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }

  String _subtitleFor(MatchEvent event) {
    if (event.type == MatchEventType.substitution &&
        event.substitutePlayerName != null &&
        event.substitutePlayerNumber != null &&
        event.playerName != null &&
        event.playerNumber != null) {
      return 'Minute ${event.minute} • 🟢 #${event.substitutePlayerNumber} '
          '${event.substitutePlayerName} on • 🔴 #${event.playerNumber} '
          '${event.playerName} off';
    }
    return 'Minute ${event.minute} • ${event.id}';
  }

  IconData _iconFor(MatchEventType type) {
    return switch (type) {
      MatchEventType.halfStarted => Icons.play_arrow,
      MatchEventType.halfEnded => Icons.stop,
      MatchEventType.goal => Icons.sports_soccer,
      MatchEventType.yellowCard => Icons.style,
      MatchEventType.redCard => Icons.style,
      MatchEventType.offside => Icons.flag,
      MatchEventType.substitution => Icons.swap_horiz,
      MatchEventType.foul => Icons.sports,
      MatchEventType.note => Icons.note,
    };
  }
}

extension on MatchEventType {
  String get label {
    return switch (this) {
      MatchEventType.halfStarted => 'Half started',
      MatchEventType.halfEnded => 'Half ended',
      MatchEventType.goal => 'Goal',
      MatchEventType.yellowCard => 'Yellow card',
      MatchEventType.redCard => 'Red card',
      MatchEventType.offside => 'Offside',
      MatchEventType.substitution => 'Substitution',
      MatchEventType.foul => 'Foul',
      MatchEventType.note => 'Note',
    };
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
