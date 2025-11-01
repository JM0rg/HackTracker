import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/decoration_styles.dart';
import '../../../providers/game_providers.dart';
import '../../../widgets/lineup_form_dialog.dart';
import '../../scoring/screens/scoring_screen.dart';
import 'lineup_section.dart';

/// Expandable game card with lineup management
class GameCard extends ConsumerStatefulWidget {
  final Game game;
  final Team team;

  const GameCard({super.key, required this.game, required this.team});

  @override
  ConsumerState<GameCard> createState() => _GameCardState();
}

class _GameCardState extends ConsumerState<GameCard> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(GameCard oldWidget) {
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

  void _showLineupDialog() {
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

  void _startGame() async {
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

  void _navigateToScoring() {
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

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final team = widget.team;
    
    // Check if lineup is set
    final hasLineup = game.lineup != null && game.lineup!.isNotEmpty;
    
    // Button visibility logic - show for scheduled or in-progress games
    final showButtons = !team.isPersonal && 
                        (game.isScheduled || game.status == 'IN_PROGRESS') && 
                        team.canManageRoster;

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
                                color: Colors.red.withValues(alpha: 0.75),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.red.withValues(alpha: 0.3 + (0.5 * _glowAnimation.value)),
                                    blurRadius: 6 + (10 * _glowAnimation.value),
                                  ),
                                  Shadow(
                                    color: Colors.red.withValues(alpha: 0.25 + (0.4 * _glowAnimation.value)),
                                    blurRadius: 10 + (12 * _glowAnimation.value),
                                  ),
                                  Shadow(
                                    color: Colors.red.withValues(alpha: 0.2 + (0.3 * _glowAnimation.value)),
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
                        LineupSection(
                          game: game,
                          team: team,
                          hasLineup: hasLineup,
                          showButtons: showButtons,
                          onShowLineupDialog: _showLineupDialog,
                          onStartGame: _startGame,
                          onNavigateToScoring: _navigateToScoring,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

