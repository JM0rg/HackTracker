import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/team.dart';
import '../widgets/placeholder_card.dart';

/// Stats Tab - Toggle between My Stats and Team Stats
class StatsTab extends ConsumerStatefulWidget {
  final Team team;

  const StatsTab({super.key, required this.team});

  @override
  ConsumerState<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<StatsTab> {
  bool _showMyStats = true; // true = My Stats, false = Team Stats

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View toggle
        Container(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('MY STATS'), icon: Icon(Icons.person)),
              ButtonSegment(value: false, label: Text('TEAM STATS'), icon: Icon(Icons.groups)),
            ],
            selected: {_showMyStats},
            onSelectionChanged: (Set<bool> selection) {
              setState(() => _showMyStats = selection.first);
            },
          ),
        ),
        Expanded(
          child: _showMyStats
              ? _MyStatsView(team: widget.team)
              : _TeamStatsView(team: widget.team),
        ),
      ],
    );
  }
}

class _MyStatsView extends StatelessWidget {
  final Team team;

  const _MyStatsView({required this.team});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          PlaceholderCard(
            icon: Icons.sports_baseball,
            title: 'My Batting Average',
            subtitle: 'Coming soon - track at-bats to see your stats',
          ),
          SizedBox(height: 16),
          PlaceholderCard(
            icon: Icons.show_chart,
            title: 'My Performance Trend',
            subtitle: 'Your stats over time',
          ),
          SizedBox(height: 16),
          PlaceholderCard(
            icon: Icons.emoji_events,
            title: 'My Achievements',
            subtitle: 'Personal milestones and highlights',
          ),
        ],
      ),
    );
  }
}

class _TeamStatsView extends StatelessWidget {
  final Team team;

  const _TeamStatsView({required this.team});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          PlaceholderCard(
            icon: Icons.sports_baseball,
            title: 'Team Batting Average',
            subtitle: 'Coming soon - track at-bats to see stats',
          ),
          SizedBox(height: 16),
          PlaceholderCard(
            icon: Icons.star,
            title: 'Top Performers',
            subtitle: 'Player rankings and highlights',
          ),
          SizedBox(height: 16),
          PlaceholderCard(
            icon: Icons.history,
            title: 'Recent Games Summary',
            subtitle: 'Quick overview of recent performance',
          ),
        ],
      ),
    );
  }
}

