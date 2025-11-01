import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/custom_text_styles.dart';
import '../../../theme/decoration_styles.dart';
import '../widgets/liquid_glass_stat_card.dart';

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
        // View toggle with liquid glass styling
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('MY STATS'),
                      icon: Icon(Icons.person, size: 18),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('TEAM STATS'),
                      icon: Icon(Icons.groups, size: 18),
                    ),
                  ],
                  selected: {_showMyStats},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() => _showMyStats = selection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    selectedForegroundColor: AppColors.primary,
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ),
            ),
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
          // Quick Stats Row
          LiquidGlassStatRow(
            label: 'SEASON STATS',
            items: const [
              StatItem(label: 'AVG', value: '.342'),
              StatItem(label: 'HR', value: '12'),
              StatItem(label: 'RBI', value: '47'),
              StatItem(label: 'OPS', value: '1.02'),
            ],
          ),
          const SizedBox(height: 16),
          // Batting Average Card
          const LiquidGlassStatCard(
            label: 'BATTING AVERAGE',
            value: '.342',
            icon: Icons.sports_baseball,
          ),
          const SizedBox(height: 16),
          // Home Runs Card
          const LiquidGlassStatCard(
            label: 'HOME RUNS',
            value: '12',
            icon: Icons.emoji_events,
            accentColor: AppColors.warning,
          ),
          const SizedBox(height: 16),
          // RBIs Card
          const LiquidGlassStatCard(
            label: 'RUNS BATTED IN',
            value: '47',
            icon: Icons.show_chart,
            accentColor: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          // Performance Trend Card
          const LiquidGlassStatCard(
            label: 'ON BASE PLUS SLUGGING',
            value: '1.02',
            icon: Icons.trending_up,
            accentColor: AppColors.info,
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
          // Team Overview Stats
          LiquidGlassStatRow(
            label: 'TEAM STATS',
            items: const [
              StatItem(label: 'WINS', value: '8'),
              StatItem(label: 'LOSSES', value: '2'),
              StatItem(label: 'AVG', value: '.298'),
              StatItem(label: 'HR', value: '45'),
            ],
          ),
          const SizedBox(height: 16),
          // Team Batting Average Card
          const LiquidGlassStatCard(
            label: 'TEAM BATTING AVERAGE',
            value: '.298',
            icon: Icons.sports_baseball,
          ),
          const SizedBox(height: 16),
          // Win/Loss Record Card
          const LiquidGlassStatCard(
            label: 'WIN / LOSS RECORD',
            value: '8 - 2',
            icon: Icons.emoji_events,
            accentColor: AppColors.success,
          ),
          const SizedBox(height: 16),
          // Team Home Runs Card
          const LiquidGlassStatCard(
            label: 'TEAM HOME RUNS',
            value: '45',
            icon: Icons.star,
            accentColor: AppColors.warning,
          ),
          const SizedBox(height: 16),
          // Recent Performance Card
          const LiquidGlassStatCard(
            label: 'LAST 5 GAMES',
            value: '4 - 1',
            icon: Icons.history,
            accentColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

