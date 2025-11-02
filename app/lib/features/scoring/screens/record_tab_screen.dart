import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../models/game.dart';
import '../../../models/team.dart';
import '../../../providers/game_providers.dart';
import '../../../providers/team_providers.dart';
import '../../../widgets/lineup_form_dialog.dart';
import '../../../features/team/widgets/lineup_section.dart';
import 'scoring_flow_screen.dart';
import 'package:intl/intl.dart';

/// Record Tab Screen
/// 
/// Smart screen that:
/// - If a game is in progress: navigates to ScoringFlowScreen
/// - If no game in progress: shows next upcoming game details with lineup and start button
class RecordTabScreen extends ConsumerStatefulWidget {
  final String? teamId;

  const RecordTabScreen({
    super.key,
    this.teamId,
  });

  @override
  ConsumerState<RecordTabScreen> createState() => _RecordTabScreenState();
}

class _RecordTabScreenState extends ConsumerState<RecordTabScreen> {
  bool _exitedFromScoring = false;

  /// Find the in-progress game (should be only one with validation)
  Game? _findInProgressGame(List<Game> games) {
    final inProgress = games.where((g) => g.status == 'IN_PROGRESS').toList();
    if (inProgress.length > 1) {
      // Edge case: multiple in-progress games (shouldn't happen with validation)
      // Log warning and use the first one
      debugPrint('WARNING: Multiple IN_PROGRESS games found for team ${widget.teamId}');
    }
    return inProgress.isNotEmpty ? inProgress.first : null;
  }

  /// Find the next upcoming scheduled game
  Game? _findNextUpcomingGame(List<Game> games) {
    final now = DateTime.now();
    final scheduled = games.where((g) {
      if (g.status != 'SCHEDULED') return false;
      if (g.scheduledStart == null) return false;
      return g.scheduledStart!.isAfter(now);
    }).toList();
    
    if (scheduled.isEmpty) return null;
    
    // Sort by scheduledStart ascending (earliest first)
    scheduled.sort((a, b) {
      if (a.scheduledStart == null || b.scheduledStart == null) return 0;
      return a.scheduledStart!.compareTo(b.scheduledStart!);
    });
    
    return scheduled.first;
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
    if (widget.teamId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_baseball, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Select a team to record at-bats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gamesAsync = ref.watch(gamesProvider(widget.teamId!));
    final teamAsync = ref.watch(selectedTeamProvider);

    return gamesAsync.when(
      data: (games) {
        final inProgressGame = _findInProgressGame(games);
        final nextGame = _findNextUpcomingGame(games);

        // If in-progress game exists and user hasn't explicitly exited, show ScoringFlowScreen
        if (inProgressGame != null && !_exitedFromScoring) {
          return ScoringFlowScreen(
            gameId: inProgressGame.gameId,
            teamId: inProgressGame.teamId,
            onBack: () {
              // When back is pressed, set flag to show next game view instead
              setState(() {
                _exitedFromScoring = true;
              });
            },
          );
        }

        // No in-progress game - show next upcoming game or empty state
        if (nextGame == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_baseball, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming games',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Schedule a new game from the Schedule tab',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Show next upcoming game details
        final team = teamAsync;
        if (team == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Game',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (nextGame.opponentName != null) ...[
                        Row(
                          children: [
                            Icon(Icons.people, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              'vs ${nextGame.opponentName}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (nextGame.scheduledStart != null) ...[
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _formatGameDate(nextGame.scheduledStart!),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(nextGame.scheduledStart!),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (nextGame.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nextGame.location!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Lineup section
                _LineupSectionWrapper(
                  game: nextGame,
                  team: team,
                  onNavigateToScoring: () {
                    // After starting game, reset exit flag and refresh to show ScoringFlowScreen
                    setState(() {
                      _exitedFromScoring = false;
                    });
                    ref.invalidate(gamesProvider(widget.teamId!));
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load games',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper for LineupSection that provides the required callbacks
class _LineupSectionWrapper extends ConsumerStatefulWidget {
  final Game game;
  final Team team;
  final VoidCallback onNavigateToScoring;

  const _LineupSectionWrapper({
    required this.game,
    required this.team,
    required this.onNavigateToScoring,
  });

  @override
  ConsumerState<_LineupSectionWrapper> createState() => _LineupSectionWrapperState();
}

class _LineupSectionWrapperState extends ConsumerState<_LineupSectionWrapper> {
  bool get hasLineup => widget.game.lineup != null && widget.game.lineup!.isNotEmpty;
  bool get showButtons => !widget.team.isPersonal && widget.team.canManageRoster;

  void _showLineupDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => LineupFormDialog(
        teamId: widget.team.teamId,
        gameId: widget.game.gameId,
        currentLineup: widget.game.lineup,
      ),
    );
  }

  Future<void> _startGame() async {
    final actions = ref.read(gameActionsProvider(widget.game.teamId));
    try {
      final updatedGame = await actions.startGame(widget.game.gameId);
      if (updatedGame != null && mounted) {
        // Game started - navigate to scoring
        widget.onNavigateToScoring();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start game: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LineupSection(
      game: widget.game,
      team: widget.team,
      hasLineup: hasLineup,
      showButtons: showButtons,
      onShowLineupDialog: _showLineupDialog,
      onStartGame: _startGame,
      onNavigateToScoring: widget.onNavigateToScoring,
    );
  }
}
