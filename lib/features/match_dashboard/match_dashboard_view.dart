import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/match_center_tokens.dart';
import '../../ditto/ditto_manager.dart';
import '../../domain/match_control.dart';
import '../../domain/match_dashboard_summary.dart';
import '../../domain/match_event.dart';
import '../../domain/player.dart';

class MatchDashboardView extends StatelessWidget {
  const MatchDashboardView({
    super.key,
    required this.canWrite,
    required this.matchesState,
    required this.allEventsState,
    required this.presenceState,
    required this.selectedMatchId,
    required this.onMatchSelected,
    required this.onCreateMatch,
  });

  final bool canWrite;
  final AsyncValue<List<MatchControlState>> matchesState;
  final AsyncValue<List<MatchEvent>> allEventsState;
  final AsyncValue<DittoPresenceSummary> presenceState;
  final String selectedMatchId;
  final ValueChanged<String> onMatchSelected;
  final VoidCallback onCreateMatch;

  @override
  Widget build(BuildContext context) {
    final events = allEventsState.valueOrNull ?? const <MatchEvent>[];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: MatchCenterColors.pitchBlack,
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BroadcastMasthead(
              canWrite: canWrite,
              matchesState: matchesState,
              events: events,
              presenceState: presenceState,
              onCreateMatch: onCreateMatch,
            ),
            const SizedBox(height: 18),
            allEventsState.when(
              data: (_) => matchesState.when(
                data: (matches) {
                  final visibleMatches = _ensureDashboardMatches(
                    matches,
                    selectedMatchId,
                  );
                  return BroadcastDashboardLayout(
                    matches: visibleMatches,
                    events: events,
                    selectedMatchId: selectedMatchId,
                    onMatchSelected: onMatchSelected,
                  );
                },
                loading: () => const BroadcastLoadingPanel(),
                error: (error, _) => BroadcastErrorPanel(error: error),
              ),
              loading: () => const BroadcastLoadingPanel(),
              error: (error, _) => BroadcastErrorPanel(error: error),
            ),
          ],
        ),
      ),
    );
  }

  List<MatchControlState> _ensureDashboardMatches(
    List<MatchControlState> matches,
    String selectedMatchId,
  ) {
    if (matches.any((match) => match.id == selectedMatchId)) {
      return matches;
    }
    return [MatchControlState.initial(id: selectedMatchId), ...matches];
  }
}

class BroadcastMasthead extends StatelessWidget {
  const BroadcastMasthead({
    super.key,
    required this.canWrite,
    required this.matchesState,
    required this.events,
    required this.presenceState,
    required this.onCreateMatch,
  });

  final bool canWrite;
  final AsyncValue<List<MatchControlState>> matchesState;
  final List<MatchEvent> events;
  final AsyncValue<DittoPresenceSummary> presenceState;
  final VoidCallback onCreateMatch;

  @override
  Widget build(BuildContext context) {
    final matches = matchesState.valueOrNull ?? const <MatchControlState>[];
    final liveMatches = matches.where((match) => match.isHalfRunning).length;
    final goals = events
        .where((event) => event.type == MatchEventType.goal)
        .length;
    final cards = events
        .where(
          (event) =>
              event.type == MatchEventType.yellowCard ||
              event.type == MatchEventType.redCard,
        )
        .length;
    final substitutions = events
        .where((event) => event.type == MatchEventType.substitution)
        .length;

    final presenceCopy = presenceState.when(
      data: (summary) =>
          '${summary.remotePeerCount} peers · server ${summary.connectedToDittoServer ? 'online' : 'offline'}',
      loading: () => 'presence warming up',
      error: (_, _) => 'presence unavailable',
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.55,
          colors: [
            MatchCenterColors.featuredTop,
            MatchCenterColors.panel,
            MatchCenterColors.pitchBlack,
          ],
        ),
        border: Border.all(color: MatchCenterColors.borderBright),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              BroadcastLiveBadge(label: 'SCREEN SHARE'),
              BroadcastTag(label: 'LOCAL-FIRST'),
              BroadcastTag(label: 'DITTO 5.1'),
              BroadcastTag(label: 'MESH DEMO'),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final title = Text(
                'MATCH CENTRE',
                style: MatchCenterTypography.display(
                  fontSize: compact ? 44 : 70,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: compact ? -1.6 : -3.1,
                  height: 0.94,
                ),
              );

              final action = BroadcastButton(
                label: 'New match',
                icon: Icons.add,
                onPressed: canWrite ? onCreateMatch : null,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 14), action],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 18),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'A stadium-board view for every match in the local-first tournament. '
            'Phones record referee events; Ditto sync makes the dashboard converge.',
            style: MatchCenterTypography.body(fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              BroadcastStatChip(
                label: 'Matches',
                value: matches.length.toString(),
                icon: Icons.stadium,
              ),
              BroadcastStatChip(
                label: 'Live',
                value: liveMatches.toString(),
                icon: Icons.radio_button_checked,
                accentColor: MatchCenterColors.lime,
              ),
              BroadcastStatChip(
                label: 'Goals',
                value: goals.toString(),
                icon: Icons.sports_soccer,
              ),
              BroadcastStatChip(
                label: 'Cards',
                value: cards.toString(),
                icon: Icons.style,
                accentColor: MatchCenterColors.caution,
              ),
              BroadcastStatChip(
                label: 'Subs',
                value: substitutions.toString(),
                icon: Icons.swap_horiz,
              ),
              BroadcastStatChip(
                label: 'Ditto',
                value: presenceCopy,
                icon: Icons.hub,
                accentColor: MatchCenterColors.grass,
                maxValueWidth: 220,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BroadcastDashboardLayout extends StatelessWidget {
  const BroadcastDashboardLayout({
    super.key,
    required this.matches,
    required this.events,
    required this.selectedMatchId,
    required this.onMatchSelected,
  });

  final List<MatchControlState> matches;
  final List<MatchEvent> events;
  final String selectedMatchId;
  final ValueChanged<String> onMatchSelected;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const BroadcastEmptyPanel();
    }

    return StreamBuilder<int>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now().millisecondsSinceEpoch,
      ),
      initialData: DateTime.now().millisecondsSinceEpoch,
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now().millisecondsSinceEpoch;
        final summaries = matches
            .map(
              (match) => MatchDashboardSummary.fromMatch(
                match: match,
                events: events,
                nowMillis: now,
              ),
            )
            .toList();
        final featured = _featuredSummary(summaries, selectedMatchId);
        final compactMatches = summaries
            .where((summary) => summary.match.id != featured.match.id)
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1120) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        FeaturedBroadcastMatchCard(
                          summary: featured,
                          selected: featured.match.id == selectedMatchId,
                          onTap: () => onMatchSelected(featured.match.id),
                        ),
                        const SizedBox(height: 16),
                        MatchCubeGrid(
                          summaries: compactMatches,
                          selectedMatchId: selectedMatchId,
                          onMatchSelected: onMatchSelected,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 330,
                    child: BroadcastRightRail(
                      events: events,
                      matches: matches,
                      featuredMatch: featured.match,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                FeaturedBroadcastMatchCard(
                  summary: featured,
                  selected: featured.match.id == selectedMatchId,
                  onTap: () => onMatchSelected(featured.match.id),
                ),
                const SizedBox(height: 16),
                MatchCubeGrid(
                  summaries: compactMatches,
                  selectedMatchId: selectedMatchId,
                  onMatchSelected: onMatchSelected,
                ),
                const SizedBox(height: 16),
                BroadcastRightRail(
                  events: events,
                  matches: matches,
                  featuredMatch: featured.match,
                ),
              ],
            );
          },
        );
      },
    );
  }

  MatchDashboardSummary _featuredSummary(
    List<MatchDashboardSummary> summaries,
    String selectedMatchId,
  ) {
    for (final summary in summaries) {
      if (summary.match.id == selectedMatchId) return summary;
    }
    for (final summary in summaries) {
      if (summary.match.isHalfRunning) return summary;
    }
    return summaries.first;
  }
}

class FeaturedBroadcastMatchCard extends StatelessWidget {
  const FeaturedBroadcastMatchCard({
    super.key,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final MatchDashboardSummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = broadcastStatusColor(summary.match.status);

    return BroadcastInteractiveSurface(
      selected: selected,
      onTap: onTap,
      borderRadius: 30,
      child: Container(
        width: double.infinity,
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
          border: Border.all(
            color: selected ? MatchCenterColors.lime : MatchCenterColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'FEATURED MATCH · PITCH ${pitchNumberFor(summary.match.id)}',
                    style: MatchCenterTypography.label(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: MatchCenterColors.lime,
                      letterSpacing: 1.7,
                    ),
                  ),
                ),
                BroadcastStatusPill(
                  label: summary.match.statusLabel,
                  color: statusColor,
                  isLive: summary.match.isHalfRunning,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              summary.match.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MatchCenterTypography.display(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1.1,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final score = SizedBox(
                  height: compact ? 118 : 176,
                  child: Center(
                    child: Text(
                      summary.scoreLabel,
                      textAlign: TextAlign.center,
                      style: MatchCenterTypography.display(
                        fontSize: compact ? 84 : 118,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: compact ? -4 : -6,
                        height: 0.82,
                      ),
                    ),
                  ),
                );

                final clock = _FeaturedClock(summary: summary);

                if (compact) {
                  return Column(
                    children: [score, const SizedBox(height: 16), clock],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: score),
                    const SizedBox(width: 22),
                    Expanded(flex: 2, child: clock),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                border: Border.all(color: MatchCenterColors.borderBright),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt,
                    color: MatchCenterColors.lime,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary.latestEventLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MatchCenterTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MatchCenterColors.offWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedClock extends StatelessWidget {
  const _FeaturedClock({required this.summary});

  final MatchDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BroadcastMetricBox(
          icon: summary.match.isHalfRunning ? Icons.timer : Icons.timer_off,
          label: 'Clock',
          value: summary.clockLabel,
        ),
        const SizedBox(height: 10),
        BroadcastMetricBox(
          icon: Icons.hourglass_bottom,
          label: 'Remaining',
          value: summary.timeRemainingLabel.replaceFirst(' remaining', ''),
        ),
      ],
    );
  }
}

class MatchCubeGrid extends StatelessWidget {
  const MatchCubeGrid({
    super.key,
    required this.summaries,
    required this.selectedMatchId,
    required this.onMatchSelected,
  });

  final List<MatchDashboardSummary> summaries;
  final String selectedMatchId;
  final ValueChanged<String> onMatchSelected;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          >= 1040 => 3,
          >= 720 => 2,
          _ => 1,
        };

        return GridView.builder(
          itemCount: summaries.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final summary = summaries[index];
            return MatchCubeCard(
              summary: summary,
              selected: summary.match.id == selectedMatchId,
              onTap: () => onMatchSelected(summary.match.id),
            );
          },
        );
      },
    );
  }
}

class MatchCubeCard extends StatefulWidget {
  const MatchCubeCard({
    super.key,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final MatchDashboardSummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<MatchCubeCard> createState() => _MatchCubeCardState();
}

class _MatchCubeCardState extends State<MatchCubeCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = broadcastStatusColor(widget.summary.match.status);
    final showPromotion = _hovered || _focused;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'Feature ${widget.summary.match.name}',
      hint:
          'Shows ${widget.summary.scoreLabel} and makes this the main dashboard match.',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: BroadcastInteractiveSurface(
            selected: widget.selected || showPromotion,
            onTap: widget.onTap,
            borderRadius: 24,
            child: Stack(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 220),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.selected || showPromotion
                          ? const [
                              MatchCenterColors.featuredTop,
                              MatchCenterColors.panel,
                            ]
                          : const [
                              MatchCenterColors.panelRaised,
                              MatchCenterColors.pitchBlack,
                            ],
                    ),
                    border: Border.all(
                      color: widget.selected || showPromotion
                          ? MatchCenterColors.lime
                          : MatchCenterColors.border,
                      width: widget.selected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PITCH ${pitchNumberFor(widget.summary.match.id)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MatchCenterTypography.label(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: MatchCenterColors.muted,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          BroadcastStatusPill(
                            label: widget.summary.match.statusLabel,
                            color: statusColor,
                            isLive: widget.summary.match.isHalfRunning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.summary.match.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: MatchCenterTypography.display(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.02,
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Text(
                          widget.summary.scoreLabel,
                          style: MatchCenterTypography.display(
                            fontSize: 58,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -3,
                            height: 0.9,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: BroadcastMiniMetric(
                              icon: widget.summary.match.isHalfRunning
                                  ? Icons.timer
                                  : Icons.timer_off,
                              label: widget.summary.clockLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BroadcastMiniMetric(
                              icon: Icons.hourglass_bottom,
                              label: widget.summary.timeRemainingLabel
                                  .replaceFirst(' remaining', ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      BroadcastInfoPill(
                        icon: Icons.update,
                        label: widget.summary.latestEventLabel,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: IgnorePointer(
                    ignoring: !showPromotion,
                    child: AnimatedOpacity(
                      opacity: showPromotion ? 1 : 0,
                      duration: const Duration(milliseconds: 140),
                      child: FilledButton.icon(
                        onPressed: widget.onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: MatchCenterColors.lime,
                          foregroundColor: MatchCenterColors.pitchBlack,
                          minimumSize: const Size(64, 48),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: const Icon(Icons.vertical_align_top, size: 16),
                        label: Text(
                          'Feature match',
                          style: MatchCenterTypography.label(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: MatchCenterColors.pitchBlack,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BroadcastRightRail extends StatelessWidget {
  const BroadcastRightRail({
    super.key,
    required this.events,
    required this.matches,
    required this.featuredMatch,
  });

  final List<MatchEvent> events;
  final List<MatchControlState> matches;
  final MatchControlState featuredMatch;

  @override
  Widget build(BuildContext context) {
    final latestEvents =
        events.where((event) => event.matchId == featuredMatch.id).toList()
          ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    final liveMatches = matches.where((match) => match.isHalfRunning).toList();

    return Column(
      children: [
        BroadcastRailPanel(
          title: 'Team timeline',
          icon: Icons.dynamic_feed,
          child: ScrollableTeamTimeline(
            events: latestEvents,
            homeTeamName: teamNameForSide(TeamSide.home),
            awayTeamName: teamNameForSide(TeamSide.away),
          ),
        ),
        const SizedBox(height: 14),
        BroadcastRailPanel(
          title: 'Live pitches',
          icon: Icons.settings_input_antenna,
          child: liveMatches.isEmpty
              ? Text(
                  'No halves are running right now.',
                  style: MatchCenterTypography.body(fontSize: 13),
                )
              : Column(
                  children: [
                    for (final match in liveMatches.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: MatchCenterColors.lime,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                match.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MatchCenterTypography.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: MatchCenterColors.offWhite,
                                ),
                              ),
                            ),
                            Text(
                              match.selectedHalfLabel,
                              style: MatchCenterTypography.label(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class BroadcastRailPanel extends StatelessWidget {
  const BroadcastRailPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MatchCenterColors.panelAlt,
        border: Border.all(color: MatchCenterColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: MatchCenterColors.lime, size: 18),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: MatchCenterTypography.label(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: MatchCenterColors.offWhite,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class ScrollableTeamTimeline extends StatefulWidget {
  const ScrollableTeamTimeline({
    super.key,
    required this.events,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final List<MatchEvent> events;
  final String homeTeamName;
  final String awayTeamName;

  @override
  State<ScrollableTeamTimeline> createState() => _ScrollableTeamTimelineState();
}

class _ScrollableTeamTimelineState extends State<ScrollableTeamTimeline> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeline = TeamSideTimeline(
      events: widget.events,
      homeTeamName: widget.homeTeamName,
      awayTeamName: widget.awayTeamName,
    );

    if (widget.events.length <= 6) {
      return timeline;
    }

    return SizedBox(
      height: 420,
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controller,
          padding: const EdgeInsets.only(right: 12),
          child: timeline,
        ),
      ),
    );
  }
}

class TeamSideTimeline extends StatelessWidget {
  const TeamSideTimeline({
    super.key,
    required this.events,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final List<MatchEvent> events;
  final String homeTeamName;
  final String awayTeamName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamTimelineHeader(
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          Text(
            'No match events have been logged yet.',
            style: MatchCenterTypography.body(fontSize: 13),
          )
        else
          for (final event in events) TeamSideTimelineRow(event: event),
      ],
    );
  }
}

class TeamTimelineHeader extends StatelessWidget {
  const TeamTimelineHeader({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final String homeTeamName;
  final String awayTeamName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            homeTeamName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: MatchCenterTypography.label(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: MatchCenterColors.lime,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(
          width: 46,
          child: Icon(
            Icons.sports_soccer,
            color: MatchCenterColors.muted,
            size: 15,
          ),
        ),
        Expanded(
          child: Text(
            awayTeamName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MatchCenterTypography.label(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: MatchCenterColors.offWhite,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class TeamSideTimelineRow extends StatelessWidget {
  const TeamSideTimelineRow({super.key, required this.event});

  final MatchEvent event;

  @override
  Widget build(BuildContext context) {
    final side = event.teamSide;
    final isHome = side == TeamSide.home;
    final isAway = side == TeamSide.away;
    final accent = _eventColor(event.type);

    if (!isHome && !isAway) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            NeutralTimelineMarker(event: event, accent: accent),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }

    final bubble = TimelineEventBubble(
      event: event,
      alignRight: isHome,
      accent: accent,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: isAway
                ? const SizedBox.shrink()
                : Align(
                    alignment: isHome
                        ? Alignment.centerRight
                        : Alignment.center,
                    child: bubble,
                  ),
          ),
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Container(
                  width: 1,
                  height: 18,
                  color: MatchCenterColors.border,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: MatchCenterColors.pitchBlack,
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${event.minute}’',
                    style: MatchCenterTypography.label(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: MatchCenterColors.offWhite,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 18,
                  color: MatchCenterColors.border,
                ),
              ],
            ),
          ),
          Expanded(
            child: isAway
                ? Align(alignment: Alignment.centerLeft, child: bubble)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class TimelineEventBubble extends StatelessWidget {
  const TimelineEventBubble({
    super.key,
    required this.event,
    required this.alignRight,
    required this.accent,
  });

  final MatchEvent event;
  final bool alignRight;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 138),
      child: Container(
        decoration: BoxDecoration(
          color: event.type == MatchEventType.goal
              ? MatchCenterColors.lime.withValues(alpha: 0.16)
              : accent.withValues(alpha: 0.12),
          border: Border.all(color: accent.withValues(alpha: 0.34)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(alignRight ? 16 : 5),
            bottomRight: Radius.circular(alignRight ? 5 : 16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Column(
          crossAxisAlignment: alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              event.teamName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              style: MatchCenterTypography.label(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: accent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: alignRight
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Icon(_eventIcon(event.type), color: accent, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _eventHeadline(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MatchCenterTypography.body(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: MatchCenterColors.offWhite,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _eventDetail(event),
              maxLines: 2,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: MatchCenterTypography.body(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  IconData _eventIcon(MatchEventType type) {
    return switch (type) {
      MatchEventType.goal => Icons.sports_soccer,
      MatchEventType.yellowCard || MatchEventType.redCard => Icons.style,
      MatchEventType.offside => Icons.flag,
      MatchEventType.substitution => Icons.swap_horiz,
      MatchEventType.halfStarted => Icons.play_arrow,
      MatchEventType.halfEnded => Icons.stop,
      MatchEventType.foul => Icons.sports,
      MatchEventType.note => Icons.notes,
    };
  }

  String _eventHeadline(MatchEvent event) {
    return switch (event.type) {
      MatchEventType.goal => 'Goal',
      MatchEventType.yellowCard => 'Yellow card',
      MatchEventType.redCard => 'Red card',
      MatchEventType.offside => 'Offside',
      MatchEventType.substitution => 'Substitution',
      MatchEventType.halfStarted => 'Half started',
      MatchEventType.halfEnded => 'Half ended',
      MatchEventType.foul => 'Foul',
      MatchEventType.note => 'Note',
    };
  }

  String _eventDetail(MatchEvent event) {
    if (event.type == MatchEventType.substitution &&
        event.playerName != null &&
        event.playerNumber != null &&
        event.substitutePlayerName != null &&
        event.substitutePlayerNumber != null) {
      return '⬆ #${event.substitutePlayerNumber} ${event.substitutePlayerName}\n'
          '⬇ #${event.playerNumber} ${event.playerName}';
    }

    if (event.playerName != null && event.playerNumber != null) {
      return '#${event.playerNumber} ${event.playerName}';
    }

    return event.subjectLabel;
  }
}

class NeutralTimelineMarker extends StatelessWidget {
  const NeutralTimelineMarker({
    super.key,
    required this.event,
    required this.accent,
  });

  final MatchEvent event;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          border: Border.all(color: accent.withValues(alpha: 0.44)),
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_neutralEventIcon(event.type), color: accent, size: 15),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                '${_neutralEventHeadline(event.type)} • ${event.minute}’',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: MatchCenterTypography.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: MatchCenterColors.offWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _neutralEventIcon(MatchEventType type) {
  return switch (type) {
    MatchEventType.halfStarted => Icons.play_arrow,
    MatchEventType.halfEnded => Icons.stop,
    MatchEventType.goal => Icons.sports_soccer,
    MatchEventType.yellowCard || MatchEventType.redCard => Icons.style,
    MatchEventType.offside => Icons.flag,
    MatchEventType.substitution => Icons.swap_horiz,
    MatchEventType.foul => Icons.sports,
    MatchEventType.note => Icons.notes,
  };
}

String _neutralEventHeadline(MatchEventType type) {
  return switch (type) {
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

class BroadcastButton extends StatelessWidget {
  const BroadcastButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return MatchCenterColors.textMuted.withValues(alpha: 0.18);
          }
          if (states.contains(WidgetState.pressed)) {
            return MatchCenterColors.grass;
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFDFFF70);
          }
          return MatchCenterColors.lime;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return MatchCenterColors.textMuted;
          }
          return MatchCenterColors.pitchBlack;
        }),
        overlayColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.16),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        textStyle: WidgetStateProperty.all(
          MatchCenterTypography.label(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: MatchCenterColors.pitchBlack,
            letterSpacing: 0.4,
          ),
        ),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class BroadcastInteractiveSurface extends StatelessWidget {
  const BroadcastInteractiveSurface({
    super.key,
    required this.child,
    required this.onTap,
    required this.selected,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: selected
                ? MatchCenterColors.lime.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.22),
            blurRadius: selected ? 30 : 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          mouseCursor: SystemMouseCursors.click,
          hoverColor: MatchCenterColors.lime.withValues(alpha: 0.06),
          focusColor: MatchCenterColors.lime.withValues(alpha: 0.10),
          splashColor: MatchCenterColors.lime.withValues(alpha: 0.16),
          child: child,
        ),
      ),
    );
  }
}

class BroadcastLiveBadge extends StatelessWidget {
  const BroadcastLiveBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MatchCenterColors.lime.withValues(alpha: 0.12),
        border: Border.all(
          color: MatchCenterColors.lime.withValues(alpha: 0.42),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: MatchCenterColors.lime,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: MatchCenterTypography.label(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: MatchCenterColors.lime,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class BroadcastTag extends StatelessWidget {
  const BroadcastTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: MatchCenterTypography.label(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: MatchCenterColors.textSoft,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class BroadcastStatChip extends StatelessWidget {
  const BroadcastStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor = Colors.white,
    this.maxValueWidth = 180,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final double maxValueWidth;

  @override
  Widget build(BuildContext context) {
    final responsiveValueWidth = MediaQuery.sizeOf(context).width < 520
        ? maxValueWidth.clamp(0, 92).toDouble()
        : maxValueWidth;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 9),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsiveValueWidth),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MatchCenterTypography.body(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: MatchCenterTypography.label(
              fontSize: 12,
              color: MatchCenterColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class BroadcastMetricBox extends StatelessWidget {
  const BroadcastMetricBox({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: MatchCenterColors.lime, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: MatchCenterTypography.label(fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: MatchCenterTypography.display(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BroadcastMiniMetric extends StatelessWidget {
  const BroadcastMiniMetric({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: MatchCenterColors.lime),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MatchCenterTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BroadcastStatusPill extends StatelessWidget {
  const BroadcastStatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.isLive,
  });

  final String label;
  final Color color;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.36)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MatchCenterTypography.label(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class BroadcastInfoPill extends StatelessWidget {
  const BroadcastInfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: MatchCenterColors.lime),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MatchCenterTypography.body(
                fontSize: 12,
                color: MatchCenterColors.offWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BroadcastLoadingPanel extends StatelessWidget {
  const BroadcastLoadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MatchCenterColors.panel,
        border: Border.all(color: MatchCenterColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loading match control...',
            style: MatchCenterTypography.body(
              fontWeight: FontWeight.w800,
              color: MatchCenterColors.offWhite,
            ),
          ),
          const SizedBox(height: 14),
          const LinearProgressIndicator(
            color: MatchCenterColors.lime,
            backgroundColor: MatchCenterColors.border,
          ),
        ],
      ),
    );
  }
}

class BroadcastEmptyPanel extends StatelessWidget {
  const BroadcastEmptyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MatchCenterColors.panel,
        border: Border.all(color: MatchCenterColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Text(
        'No matches yet. Create a match to light up the board.',
        style: MatchCenterTypography.body(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: MatchCenterColors.offWhite,
        ),
      ),
    );
  }
}

class BroadcastErrorPanel extends StatelessWidget {
  const BroadcastErrorPanel({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MatchCenterColors.danger.withValues(alpha: 0.10),
        border: Border.all(color: MatchCenterColors.danger),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(18),
      child: SelectableText(
        'Dashboard error: $error',
        style: MatchCenterTypography.body(
          fontSize: 13,
          color: MatchCenterColors.offWhite,
        ),
      ),
    );
  }
}

Color broadcastStatusColor(MatchStatus status) {
  return switch (status) {
    MatchStatus.firstHalf || MatchStatus.secondHalf => MatchCenterColors.lime,
    MatchStatus.halftime => MatchCenterColors.caution,
    MatchStatus.fullTime => MatchCenterColors.textSoft,
    MatchStatus.notStarted => MatchCenterColors.muted,
  };
}

int pitchNumberFor(String id) {
  final hash = id.codeUnits.fold<int>(0, (sum, value) => sum + value);
  return (hash % 8) + 1;
}
