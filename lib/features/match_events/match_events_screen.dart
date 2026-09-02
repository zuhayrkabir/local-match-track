import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/match_center_tokens.dart';
import '../../domain/app_role.dart';
import '../../domain/match_control.dart';
import '../../domain/match_event.dart';
import '../../domain/match_review_proposal.dart';
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
  MatchEventType _selectedReviewType = MatchEventType.offside;
  TeamSide _selectedReviewTeamSide = TeamSide.home;
  DemoPlayer _selectedReviewPlayer = demoPlayersForSide(TeamSide.home).first;
  final Set<String> _shownReviewProposalIds = {};
  Timer? _participantHeartbeatTimer;
  String? _participantHeartbeatKey;

  @override
  void dispose() {
    _participantHeartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = ref.watch(selectedRoleProvider);
    final managerState = ref.watch(dittoManagerProvider);
    final matchesState = ref.watch(matchesProvider);
    final matchControlState = ref.watch(matchControlProvider);
    final allEventsState = ref.watch(allMatchEventsProvider);
    final pendingReviewProposalsState = ref.watch(
      pendingReviewProposalsProvider,
    );
    final refereeOnlineState = ref.watch(refereeOnlineProvider);
    final presenceState = ref.watch(dittoPresenceSummaryProvider);
    final showDashboard = ref.watch(showDashboardProvider);
    final selectedMatchId = ref.watch(selectedMatchIdProvider);
    final selectedEventsState = allEventsState.whenData((events) {
      return events.where((event) => event.matchId == selectedMatchId).toList()
        ..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis));
    });
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
    _configureParticipantHeartbeat(
      selectedRole,
      selectedMatchId,
      managerState.valueOrNull?.dataAccessReady ?? false,
    );
    _queueReviewProposalPopup(selectedRole, pendingReviewProposalsState);

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
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF182A12), MatchCenterColors.pitchBlack],
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
                selectedMatchId: selectedMatchId,
                onMatchSelected: (matchId) {
                  ref.read(selectedMatchIdProvider.notifier).state = matchId;
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
                eventsState: selectedEventsState,
                matchControlState: matchControlState,
              ),
              const SizedBox(height: 16),
              _MatchSessionCard(
                canWrite: canWrite,
                matchesState: matchesState,
                selectedMatchId: selectedMatchId,
                onMatchSelected: (matchId) {
                  if (matchId == null) return;
                  ref.read(selectedMatchIdProvider.notifier).state = matchId;
                },
                onCreateMatch: _createMatch,
                onDeleteMatch: _deleteSelectedMatch,
              ),
              const SizedBox(height: 16),
              if (selectedRole.canReviewProposals) ...[
                _ReviewRequestsPanel(
                  proposalsState: pendingReviewProposalsState,
                  onAccept: _acceptReviewProposal,
                  onReject: _rejectReviewProposal,
                ),
                const SizedBox(height: 16),
              ],
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
              ] else if (selectedRole.canProposeReviews) ...[
                _AssistantReviewProposalCard(
                  dittoReady:
                      managerState.valueOrNull?.dataAccessReady ?? false,
                  refereeOnlineState: refereeOnlineState,
                  selectedReviewType: _selectedReviewType,
                  selectedTeamSide: _selectedReviewTeamSide,
                  selectedPlayer: _selectedReviewPlayer,
                  onReviewTypeChanged: (type) {
                    if (type == null) return;
                    setState(() => _selectedReviewType = type);
                  },
                  onTeamChanged: (teamSide) {
                    if (teamSide == null) return;
                    setState(() {
                      _selectedReviewTeamSide = teamSide;
                      _selectedReviewPlayer = demoPlayersForSide(teamSide)
                          .first;
                    });
                  },
                  onPlayerChanged: (player) {
                    if (player == null) return;
                    setState(() => _selectedReviewPlayer = player);
                  },
                  onProposeReview: _proposeReview,
                ),
              ] else
                const _SpectatorNotice(),
              const SizedBox(height: 16),
              const _RosterCard(),
              const SizedBox(height: 16),
              Text(
                'MATCH TIMELINE',
                style: MatchCenterTypography.label(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: MatchCenterColors.lime,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              selectedEventsState.when(
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

  Future<void> _proposeReview() async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.proposeReview(
        type: _selectedReviewType,
        teamSide: _selectedReviewTeamSide,
        player: _selectedReviewPlayer,
      );
      _showSnackBar('Review sent to the main referee.');
    } catch (error) {
      _showSnackBar('Could not propose review: $error');
    }
  }

  Future<void> _acceptReviewProposal(MatchReviewProposal proposal) async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.acceptReviewProposal(proposal);
      _showSnackBar('Accepted ${proposal.label.toLowerCase()}.');
    } catch (error) {
      _showSnackBar('Could not accept review: $error');
    }
  }

  Future<void> _rejectReviewProposal(MatchReviewProposal proposal) async {
    final repository = await ref.read(matchEventRepositoryProvider.future);
    try {
      await repository.rejectReviewProposal(proposal);
      _showSnackBar('Rejected ${proposal.label.toLowerCase()}.');
    } catch (error) {
      _showSnackBar('Could not reject review: $error');
    }
  }

  void _configureParticipantHeartbeat(
    AppRole role,
    String matchId,
    bool dittoReady,
  ) {
    final heartbeatKey = '$dittoReady|${role.name}|$matchId';
    if (_participantHeartbeatKey == heartbeatKey) return;

    _participantHeartbeatKey = heartbeatKey;
    _participantHeartbeatTimer?.cancel();
    _participantHeartbeatTimer = null;

    if (!dittoReady) return;

    _publishParticipantHeartbeat(role);
    _participantHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _publishParticipantHeartbeat(role),
    );
  }

  Future<void> _publishParticipantHeartbeat(AppRole role) async {
    try {
      final repository = await ref.read(matchEventRepositoryProvider.future);
      await repository.publishParticipantHeartbeat(role);
    } catch (_) {
      // Ditto startup and auth errors are already shown in the status card.
      // Heartbeat failures should not interrupt read-only match viewing.
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _queueReviewProposalPopup(
    AppRole selectedRole,
    AsyncValue<List<MatchReviewProposal>> proposalsState,
  ) {
    if (!selectedRole.canReviewProposals) return;
    final proposals = proposalsState.valueOrNull;
    if (proposals == null || proposals.isEmpty) return;

    final unseenProposals = proposals.where(
      (proposal) => !_shownReviewProposalIds.contains(proposal.id),
    );
    if (unseenProposals.isEmpty) return;

    final proposal = unseenProposals.first;
    _shownReviewProposalIds.add(proposal.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showReviewProposalDialog(proposal);
    });
  }

  Future<void> _showReviewProposalDialog(MatchReviewProposal proposal) async {
    final decision = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Assistant referee review',
            style: MatchCenterTypography.body(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: MatchCenterColors.offWhite,
            ),
          ),
          content: Text(
            '${proposal.label}\n'
            'Minute ${proposal.minute} • ${proposal.subjectLabel}',
            style: MatchCenterTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MatchCenterColors.offWhite,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Reject'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    if (decision == true) {
      await _acceptReviewProposal(proposal);
    } else if (decision == false) {
      await _rejectReviewProposal(proposal);
    }
  }
}

class _RoleSelectionScreen extends StatelessWidget {
  const _RoleSelectionScreen({required this.onRoleSelected});

  final ValueChanged<AppRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose match role')),
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
                child: Icon(_iconForRole(role), color: MatchCenterColors.lime),
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
          avatar: Icon(_iconForRole(role), size: 18),
          label: compact ? const SizedBox.shrink() : Text(role.label),
        ),
      ),
    );
  }
}

IconData _iconForRole(AppRole role) {
  return switch (role) {
    AppRole.referee => Icons.sports,
    AppRole.assistantReferee => Icons.assistant_direction,
    AppRole.spectator => Icons.visibility,
  };
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

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MatchCenterColors.panel,
        border: Border.all(color: MatchCenterColors.borderBright),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: MatchCenterColors.lime),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: MatchCenterTypography.label(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: MatchCenterColors.lime,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
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
    return _DetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailHeader(
            icon: Icons.event_available,
            title: 'Match session',
          ),
          const SizedBox(height: 12),
          matchesState.when(
            data: (matches) {
              final visibleMatches = _ensureSelectedMatchExists(matches);
              return DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue:
                    visibleMatches.any((match) => match.id == selectedMatchId)
                    ? selectedMatchId
                    : visibleMatches.first.id,
                decoration: const InputDecoration(labelText: 'Current match'),
                items: [
                  for (final match in visibleMatches)
                    DropdownMenuItem(
                      value: match.id,
                      child: Text(
                        '${match.name} • ${match.statusLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  foregroundColor: MatchCenterColors.danger,
                  side: BorderSide(
                    color: MatchCenterColors.danger.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    return _DetailPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility, color: MatchCenterColors.lime),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Spectator mode: this device can view the live score, clock, '
              'match session, roster, and timeline, but cannot change the match.',
              style: MatchCenterTypography.body(fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.45,
          colors: [
            MatchCenterColors.featuredTop,
            MatchCenterColors.panel,
            MatchCenterColors.featuredBottom,
          ],
        ),
        border: Border.all(color: MatchCenterColors.borderBright),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MatchCenterColors.lime.withValues(alpha: 0.14),
                  border: Border.all(
                    color: MatchCenterColors.lime.withValues(alpha: 0.32),
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  color: MatchCenterColors.lime,
                  size: 30,
                ),
              ),
              const Spacer(),
              const BroadcastLiveBadge(label: 'LIVE DEMO'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Green FC vs White FC',
            style: MatchCenterTypography.display(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.2,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$greenGoals - $whiteGoals',
            style: MatchCenterTypography.display(
              fontSize: 76,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -3.8,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$status • Score is derived from synced goal events.',
            style: MatchCenterTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MatchCenterColors.offWhite.withValues(alpha: 0.86),
            ),
          ),
          if (matchControl != null) ...[
            const SizedBox(height: 16),
            _MatchClockPill(matchControl: matchControl),
          ],
        ],
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
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: MatchCenterColors.borderBright),
          ),
          child: Row(
            children: [
              Icon(
                matchControl.isHalfRunning ? Icons.timer : Icons.timer_off,
                color: MatchCenterColors.lime,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${matchControl.clockLabelAt(now)}'
                  ' • Match minute ${matchControl.matchMinuteAt(now)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MatchCenterTypography.label(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
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

    return _DetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailHeader(
            icon: Icons.timer,
            title: 'Main referee controls',
          ),
          const SizedBox(height: 8),
          Text(
            'Current state: ${state.statusLabel}',
            style: MatchCenterTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MatchCenterColors.offWhite,
            ),
          ),
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

    return _DetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailHeader(
            icon: Icons.edit_note,
            title: 'Log official event',
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
    );
  }
}

class _AssistantReviewProposalCard extends StatelessWidget {
  const _AssistantReviewProposalCard({
    required this.dittoReady,
    required this.refereeOnlineState,
    required this.selectedReviewType,
    required this.selectedTeamSide,
    required this.selectedPlayer,
    required this.onReviewTypeChanged,
    required this.onTeamChanged,
    required this.onPlayerChanged,
    required this.onProposeReview,
  });

  final bool dittoReady;
  final AsyncValue<bool> refereeOnlineState;
  final MatchEventType selectedReviewType;
  final TeamSide selectedTeamSide;
  final DemoPlayer selectedPlayer;
  final ValueChanged<MatchEventType?> onReviewTypeChanged;
  final ValueChanged<TeamSide?> onTeamChanged;
  final ValueChanged<DemoPlayer?> onPlayerChanged;
  final VoidCallback onProposeReview;

  @override
  Widget build(BuildContext context) {
    const reviewTypes = [MatchEventType.offside, MatchEventType.foul];
    final refereeOnline = refereeOnlineState.valueOrNull ?? false;
    final canPropose = dittoReady && refereeOnline;
    final statusIcon = canPropose ? Icons.verified : Icons.lock_clock;
    final statusColor = canPropose
        ? MatchCenterColors.grass
        : MatchCenterColors.caution;
    final statusMessage = !dittoReady
        ? 'Ditto is still starting. You can view the match once local data is ready.'
        : refereeOnline
        ? 'Main referee online. You can send review proposals for this match.'
        : 'You can view the match, but cannot send review proposals until a referee is online.';

    return _DetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailHeader(
            icon: Icons.assistant_direction,
            title: 'Assistant review proposal',
          ),
          const SizedBox(height: 8),
          Text(
            'Suggest a call without changing the official timeline. The main '
            'referee accepts or rejects it from their device.',
            style: MatchCenterTypography.body(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              border: Border.all(color: statusColor.withValues(alpha: 0.38)),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: MatchCenterTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MatchEventType>(
            initialValue: selectedReviewType,
            decoration: const InputDecoration(labelText: 'Review type'),
            items: [
              for (final type in reviewTypes)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: canPropose ? onReviewTypeChanged : null,
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
            onSelectionChanged: canPropose
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
            onChanged: canPropose ? onPlayerChanged : null,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: canPropose ? onProposeReview : null,
            icon: const Icon(Icons.send),
            label: const Text('Send to main referee'),
          ),
        ],
      ),
    );
  }
}

class _ReviewRequestsPanel extends StatelessWidget {
  const _ReviewRequestsPanel({
    required this.proposalsState,
    required this.onAccept,
    required this.onReject,
  });

  final AsyncValue<List<MatchReviewProposal>> proposalsState;
  final ValueChanged<MatchReviewProposal> onAccept;
  final ValueChanged<MatchReviewProposal> onReject;

  @override
  Widget build(BuildContext context) {
    return proposalsState.when(
      data: (proposals) {
        if (proposals.isEmpty) {
          return _DetailPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified, color: MatchCenterColors.grass),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No assistant referee reviews pending.',
                    style: MatchCenterTypography.body(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const RadialGradient(
              center: Alignment.topLeft,
              radius: 1.35,
              colors: [
                Color(0xFF3B2F10),
                MatchCenterColors.panel,
                MatchCenterColors.pitchBlack,
              ],
            ),
            border: Border.all(color: MatchCenterColors.caution, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: MatchCenterColors.caution.withValues(alpha: 0.13),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DetailHeader(
                icon: Icons.notification_important,
                title: 'Assistant referee review',
              ),
              const SizedBox(height: 10),
              Text(
                'A synced review request is waiting for the main referee.',
                style: MatchCenterTypography.body(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final proposal in proposals) ...[
                _ReviewProposalTile(
                  proposal: proposal,
                  onAccept: () => onAccept(proposal),
                  onReject: () => onReject(proposal),
                ),
                if (proposal != proposals.last) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _ErrorText(error: error),
    );
  }
}

class _ReviewProposalTile extends StatelessWidget {
  const _ReviewProposalTile({
    required this.proposal,
    required this.onAccept,
    required this.onReject,
  });

  final MatchReviewProposal proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: MatchCenterColors.borderBright),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _eventColor(proposal.type)
                    .withValues(alpha: 0.18),
                foregroundColor: _eventColor(proposal.type),
                child: Icon(
                  proposal.type == MatchEventType.offside
                      ? Icons.flag
                      : Icons.sports,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.label,
                      style: MatchCenterTypography.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: MatchCenterColors.offWhite,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Minute ${proposal.minute} • ${proposal.subjectLabel}',
                      style: MatchCenterTypography.body(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check),
                label: const Text('Accept'),
              ),
              OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
              ),
            ],
          ),
        ],
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
    return _DetailPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailHeader(icon: Icons.hub, title: 'Ditto 5.1 status'),
          const SizedBox(height: 10),
          managerState.when(
            data: (manager) => Text(
              '${manager.modeLabel}\n'
              '${manager.activationMessage}',
              style: MatchCenterTypography.body(
                fontSize: 14,
                height: 1.45,
                color: MatchCenterColors.offWhite,
              ),
            ),
            loading: () => Text(
              'Opening Ditto...',
              style: MatchCenterTypography.body(fontSize: 14),
            ),
            error: (error, _) => _ErrorText(error: error),
          ),
          const SizedBox(height: 10),
          presenceState.when(
            data: (summary) => Text(
              'Device: ${summary.localPeerName}\n'
              'Remote peers visible: ${summary.remotePeerCount}\n'
              'Connected to Ditto Server: ${summary.connectedToDittoServer}',
              style: MatchCenterTypography.body(fontSize: 14, height: 1.45),
            ),
            loading: () => Text(
              'Waiting for presence graph...',
              style: MatchCenterTypography.body(fontSize: 14),
            ),
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
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events});

  final List<MatchEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _DetailPanel(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stadium,
                  size: 48,
                  color: MatchCenterColors.lime,
                ),
                const SizedBox(height: 12),
                Text(
                  'No events yet. Use the referee controls to kick things off.',
                  textAlign: TextAlign.center,
                  style: MatchCenterTypography.body(fontSize: 14),
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: MatchCenterColors.panel,
              border: Border.all(color: MatchCenterColors.borderBright),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _eventColor(event.type)
                    .withValues(alpha: 0.18),
                foregroundColor: _eventColor(event.type),
                child: Icon(_iconFor(event.type)),
              ),
              title: Text(
                '${event.label} — ${event.subjectLabel}',
                style: MatchCenterTypography.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: MatchCenterColors.offWhite,
                ),
              ),
              subtitle: Text(
                _subtitleFor(event),
                style: MatchCenterTypography.body(fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: MatchCenterColors.textSoft,
              ),
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

Color _eventColor(MatchEventType type) {
  return switch (type) {
    MatchEventType.goal => MatchCenterColors.lime,
    MatchEventType.yellowCard => MatchCenterColors.caution,
    MatchEventType.redCard => MatchCenterColors.danger,
    MatchEventType.offside => MatchCenterColors.grass,
    MatchEventType.substitution => MatchCenterColors.grass,
    MatchEventType.halfStarted => MatchCenterColors.lime,
    MatchEventType.halfEnded => MatchCenterColors.textSoft,
    MatchEventType.foul => MatchCenterColors.caution,
    MatchEventType.note => MatchCenterColors.textSoft,
  };
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
