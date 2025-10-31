import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/decoration_styles.dart';
import '../services/api_service.dart';
import '../providers/team_providers.dart';
import '../providers/player_providers.dart';
import '../providers/game_providers.dart';
import '../widgets/player_form_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/lineup_form_dialog.dart';
import '../widgets/game_form_dialog.dart';
import '../screens/scoring_screen.dart';

/// Team View - Shows team-specific stats, schedule, roster, and chat
class TeamViewScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRecruiter;
  
  const TeamViewScreen({super.key, this.onNavigateToRecruiter});

  @override
  ConsumerState<TeamViewScreen> createState() => _TeamViewScreenState();
}

class _TeamViewScreenState extends ConsumerState<TeamViewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);

    // Set initial selected team if none is selected
    teamsAsync.whenData((teams) {
      if (teams.isNotEmpty && selectedTeam == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedTeamProvider.notifier).state = teams.first;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          elevation: 0,
          backgroundColor: AppColors.background,
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          flexibleSpace: Column(
            children: [
              // Tabs with underline indicator
              Container(
                height: 48,
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontFamily: 'Tektur',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Tektur',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  tabs: const [
                    Tab(text: 'STATS'),
                    Tab(text: 'SCHEDULE'),
                    Tab(text: 'ROSTER'),
                    Tab(text: 'CHAT'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: selectedTeam == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _StatsTab(team: selectedTeam),
                _ScheduleTab(team: selectedTeam),
                _RosterTab(team: selectedTeam),
                _ChatTab(team: selectedTeam),
              ],
            ),
    );
  }
}

/// Stats Tab - Placeholder for future statistics
class _StatsTab extends ConsumerStatefulWidget {
  final Team team;

  const _StatsTab({required this.team});

  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
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
        children: [
          _PlaceholderCard(
            icon: Icons.sports_baseball,
            title: 'My Batting Average',
            subtitle: 'Coming soon - track at-bats to see your stats',
          ),
          const SizedBox(height: 16),
          _PlaceholderCard(
            icon: Icons.show_chart,
            title: 'My Performance Trend',
            subtitle: 'Your stats over time',
          ),
          const SizedBox(height: 16),
          _PlaceholderCard(
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
        children: [
          _PlaceholderCard(
            icon: Icons.sports_baseball,
            title: 'Team Batting Average',
            subtitle: 'Coming soon - track at-bats to see stats',
          ),
          const SizedBox(height: 16),
          _PlaceholderCard(
            icon: Icons.star,
            title: 'Top Performers',
            subtitle: 'Player rankings and highlights',
          ),
          const SizedBox(height: 16),
          _PlaceholderCard(
            icon: Icons.history,
            title: 'Recent Games Summary',
            subtitle: 'Quick overview of recent performance',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: DecorationStyles.surfaceContainer(),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Schedule Tab - List and calendar view of games
class _ScheduleTab extends ConsumerStatefulWidget {
  final Team team;

  const _ScheduleTab({required this.team});

  @override
  ConsumerState<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<_ScheduleTab> {
  bool _isListView = true; // true = list, false = calendar

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider(widget.team.teamId));

    return Stack(
      children: [
        Column(
          children: [
            // View toggle
            Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('LIST'), icon: Icon(Icons.list)),
                  ButtonSegment(value: false, label: Text('CALENDAR'), icon: Icon(Icons.calendar_month)),
                ],
                selected: {_isListView},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() => _isListView = selection.first);
                },
              ),
            ),
            Expanded(
              child: _isListView
                  ? _GameListView(team: widget.team, gamesAsync: gamesAsync)
                  : _GameCalendarView(team: widget.team, gamesAsync: gamesAsync),
            ),
          ],
        ),
        // Add Game button (owner only)
        if (widget.team.isOwner)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  enableDrag: true,
                  builder: (_) => GameFormDialog(teamId: widget.team.teamId),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _GameListView extends StatelessWidget {
  final Team team;
  final AsyncValue<List<Game>> gamesAsync;

  const _GameListView({required this.team, required this.gamesAsync});

  Map<String, List<Game>> _groupGamesByDateRange(List<Game> games) {
    final now = DateTime.now();
    final thisWeekEnd = now.add(Duration(days: 7 - now.weekday));
    final nextWeekEnd = thisWeekEnd.add(const Duration(days: 7));
    
    final Map<String, List<Game>> grouped = {
      'This Week': [],
      'Next Week': [],
      'Later': [],
    };
    
    // Include scheduled and in-progress games
    final scheduledGames = games.where((g) => 
      g.status == 'SCHEDULED' || g.status == 'IN_PROGRESS'
    ).toList();
    
    for (final game in scheduledGames) {
      if (game.scheduledStart == null) {
        grouped['Later']!.add(game);
      } else if (game.scheduledStart!.isBefore(thisWeekEnd)) {
        grouped['This Week']!.add(game);
      } else if (game.scheduledStart!.isBefore(nextWeekEnd)) {
        grouped['Next Week']!.add(game);
      } else {
        grouped['Later']!.add(game);
      }
    }
    
    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return gamesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (games) {
        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_baseball, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text(
                  'No games scheduled',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to schedule your first game',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        final groupedGames = _groupGamesByDateRange(games);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            for (var entry in groupedGames.entries) ...[
              if (entry != groupedGames.entries.first) const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...entry.value.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GameCard(game: game, team: team),
              )),
            ],
          ],
        );
      },
    );
  }
}

class _GameCard extends ConsumerStatefulWidget {
  final Game game;
  final Team team;

  const _GameCard({required this.game, required this.team});

  @override
  ConsumerState<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends ConsumerState<_GameCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Start animation if game is in progress
    if (widget.game.status == 'IN_PROGRESS') {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start/stop animation based on game status
    if (widget.game.status == 'IN_PROGRESS' && oldWidget.game.status != 'IN_PROGRESS') {
      _glowController.repeat(reverse: true);
    } else if (widget.game.status != 'IN_PROGRESS' && oldWidget.game.status == 'IN_PROGRESS') {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  String _formatGameDate(DateTime date) {
    final day = DateFormat('EEEE').format(date);
    final month = DateFormat('MMMM').format(date);
    final dayNum = date.day;
    final suffix = _getDaySuffix(dayNum);
    
    return '$day, $month $dayNum$suffix';
  }

  String _formatTime(DateTime date) {
    return DateFormat.jm().format(date);
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final team = widget.team;
    
    // Check if lineup is set
    final hasLineup = game.lineup != null && game.lineup!.isNotEmpty;
    
    // Button visibility logic - show for scheduled or in-progress games
    final showStartButton = !team.isPersonal && 
                            (game.isScheduled || game.status == 'IN_PROGRESS') && 
                            team.canManageRoster;
    final showSetLineupButton = showStartButton;

    return GestureDetector(
      onTap: _toggleExpansion,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: DecorationStyles.surfaceContainerSmall(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with game info
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (game.scheduledStart != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _formatGameDate(game.scheduledStart!),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'vs ${game.opponentName ?? 'TBD'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (game.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                game.location!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (game.isFinal) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Score: ${game.teamScore} - ${game.opponentScore}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Right side: Time/Status, Lineup status, and chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (game.status == 'IN_PROGRESS')
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Text(
                              'IN PROGRESS',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.red.withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.red.withOpacity(0.3 + (0.5 * _glowAnimation.value)),
                                    blurRadius: 6 + (10 * _glowAnimation.value),
                                  ),
                                  Shadow(
                                    color: Colors.red.withOpacity(0.25 + (0.4 * _glowAnimation.value)),
                                    blurRadius: 10 + (12 * _glowAnimation.value),
                                  ),
                                  Shadow(
                                    color: Colors.red.withOpacity(0.2 + (0.3 * _glowAnimation.value)),
                                    blurRadius: 14 + (14 * _glowAnimation.value),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else if (game.scheduledStart != null)
                        Text(
                          _formatTime(game.scheduledStart!),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasLineup) ...[
                            Text(
                              'Lineup set',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded content: Lineup section with smooth animation
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Column(
                      children: [
                        const Divider(height: 24),
                        _buildLineupSection(context, hasLineup, showSetLineupButton, showStartButton),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineupSection(BuildContext context, bool hasLineup, bool showSetLineupButton, bool showStartButton) {
    final game = widget.game;
    final rosterAsync = ref.watch(rosterProvider(widget.team.teamId));

    return rosterAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading roster: $e'),
      ),
      data: (players) {
        if (!hasLineup) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LINEUP',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No lineup set',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (showSetLineupButton || showStartButton) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // SET LINEUP button
                      if (showSetLineupButton)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showLineupDialog(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('SET LINEUP'),
                          ),
                        ),
                      if (showSetLineupButton && showStartButton) const SizedBox(width: 12),
                      // START GAME / VIEW GAME button
                      if (showStartButton)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // No lineup set - show dialog
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Lineup Required'),
                                  content: const Text('You must set a lineup first'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textTertiary,  // Grey when no lineup
                              side: const BorderSide(color: AppColors.textTertiary),  // Grey border when no lineup
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              game.status == 'IN_PROGRESS' ? 'VIEW GAME' : 'START GAME',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }

        // Build lineup list
        final lineupMap = <String, int>{};
        if (game.lineup != null) {
          for (final item in game.lineup!) {
            if (item is Map<String, dynamic>) {
              final playerId = item['playerId'] as String?;
              final battingOrder = item['battingOrder'] as int?;
              if (playerId != null && battingOrder != null) {
                lineupMap[playerId] = battingOrder;
              }
            }
          }
        }

        final sortedLineup = lineupMap.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LINEUP',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...sortedLineup.map((entry) {
                final player = players.firstWhere(
                  (p) => p.playerId == entry.key,
                  orElse: () => throw StateError('Player ${entry.key} not found in roster'),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.value.toString(),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player.fullName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '#${player.displayNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (showSetLineupButton || showStartButton) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    // SET LINEUP / EDIT LINEUP button
                    if (showSetLineupButton)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showLineupDialog(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(hasLineup ? 'EDIT LINEUP' : 'SET LINEUP'),
                        ),
                      ),
                    if (showSetLineupButton && showStartButton) const SizedBox(width: 12),
                    // START GAME / VIEW GAME button
                    if (showStartButton)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (!hasLineup) {
                              // No lineup set - show dialog
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Lineup Required'),
                                  content: const Text('You must set a lineup first'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (game.status == 'IN_PROGRESS') {
                              // Game already in progress with lineup - just navigate to scoring screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScoringScreen(
                                    gameId: game.gameId,
                                    teamId: widget.team.teamId,
                                  ),
                                ),
                              );
                            } else if (hasLineup) {
                              // Scheduled game with lineup - start it
                              _startGame(context);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: (!hasLineup)
                                ? AppColors.textTertiary  // Grey when no lineup
                                : AppColors.primary,  // Green when lineup is set
                            disabledForegroundColor: AppColors.textTertiary,
                            side: BorderSide(
                              color: (!hasLineup)
                                  ? AppColors.textTertiary  // Grey border when no lineup
                                  : AppColors.primary,  // Green border when lineup is set
                            ),
                            disabledBackgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            game.status == 'IN_PROGRESS' ? 'VIEW GAME' : 'START GAME',
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showLineupDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => LineupFormDialog(
        teamId: widget.team.teamId,
        gameId: widget.game.gameId,
        currentLineup: widget.game.lineup,
      ),
    );
  }

  void _startGame(BuildContext context) async {
    final actions = ref.read(gameActionsProvider(widget.team.teamId));
    final updatedGame = await actions.startGame(widget.game.gameId);
    
    if (updatedGame != null && mounted) {
      // Navigate to scoring screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScoringScreen(
            gameId: widget.game.gameId,
            teamId: widget.team.teamId,
          ),
        ),
      );
    }
  }
}

class _GameCalendarView extends StatelessWidget {
  final Team team;
  final AsyncValue<List<Game>> gamesAsync;

  const _GameCalendarView({required this.team, required this.gamesAsync});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Calendar View',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Roster Tab - Enhanced with roles and color-coded numbers
class _RosterTab extends ConsumerWidget {
  final Team team;

  const _RosterTab({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(team.teamId));

    return Column(
      children: [
        // Legend
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: DecorationStyles.surfaceContainerSmall(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.linkedUserColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Has Account',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.guestUserColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'No Account',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Add button (owner only)
        if (team.isOwner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    enableDrag: true,
                    builder: (_) => PlayerFormDialog(teamId: team.teamId),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('ADD PLAYER'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Roster list
        Expanded(
          child: rosterAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (players) {
              if (players.isEmpty) {
                return Center(
                  child: Text(
                    'No players on roster',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RosterPlayerCard(
                      key: ValueKey(players[index].playerId),
                      player: players[index],
                      canManage: team.isOwner,
                      onEdit: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          enableDrag: true,
                          builder: (_) => PlayerFormDialog(
                            teamId: team.teamId,
                            player: players[index],
                          ),
                        );
                      },
                      onRemove: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => ConfirmDialog(
                            title: 'REMOVE PLAYER?',
                            message: 'Remove ${players[index].fullName} from roster?',
                            confirmLabel: 'REMOVE',
                            confirmColor: AppColors.error,
                          ),
                        );
                        if (confirmed == true) {
                          final actions = ref.read(rosterActionsProvider(team.teamId));
                          await actions.removePlayer(players[index].playerId);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RosterPlayerCard extends StatelessWidget {
  final Player player;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const _RosterPlayerCard({
    super.key,
    required this.player,
    required this.canManage,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isLinked = player.userId != null;
    final numberColor = isLinked ? AppColors.linkedUserColor : AppColors.guestUserColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: DecorationStyles.surfaceContainerSmall(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Player number with color coding
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: numberColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: numberColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              player.displayNumber,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: numberColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  player.displayRole,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Positions
          if (player.positions != null && player.positions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                player.positions!.join(', '),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(width: 8),
          // Edit/Remove menu (owner only)
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textTertiary),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'remove') {
                  onRemove?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
        ],
      ),
    );
  }
}

/// Chat Tab - Placeholder for future chat feature
class _ChatTab extends StatelessWidget {
  final Team team;

  const _ChatTab({required this.team});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Team Chat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon - coordinate with your team',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

