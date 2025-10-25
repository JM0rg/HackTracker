import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Player View - Shows user's personal stats aggregated across all teams
class PlayerViewScreen extends StatelessWidget {
  final VoidCallback? onNavigateToTeamView;

  const PlayerViewScreen({
    super.key,
    this.onNavigateToTeamView,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Season/Year Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MY STATS',
                  style: GoogleFonts.tektur(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '2024',
                        style: GoogleFonts.tektur(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Stats Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'SEASON STATS',
                    style: GoogleFonts.tektur(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'AVG', value: '.342'),
                      _StatColumn(label: 'HR', value: '12'),
                      _StatColumn(label: 'RBI', value: '47'),
                      _StatColumn(label: 'OPS', value: '1.02'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // My Teams Section
            Text(
              'MY TEAMS',
              style: GoogleFonts.tektur(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // Team Cards (placeholder data)
            _TeamCard(
              teamName: 'Rockets',
              role: 'OWNER',
              onTap: () {
                if (onNavigateToTeamView != null) {
                  onNavigateToTeamView!();
                }
              },
            ),
            const SizedBox(height: 8),
            _TeamCard(
              teamName: 'Thunder',
              role: 'MEMBER',
              onTap: () {
                if (onNavigateToTeamView != null) {
                  onNavigateToTeamView!();
                }
              },
            ),

            const SizedBox(height: 20),

            // Spray Chart Placeholder
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPRAY CHART',
                    style: GoogleFonts.tektur(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_baseball,
                            size: 48,
                            color: AppColors.border,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hit location visualization coming soon',
                            style: GoogleFonts.tektur(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent Games
            Text(
              'RECENT GAMES',
              style: GoogleFonts.tektur(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // Game Cards (placeholder)
            _GameCard(
              result: 'W',
              opponent: 'vs Tigers',
              personalStats: '3-4, 2 RBI, 1 HR',
              date: 'Oct 15, 2024',
            ),
            const SizedBox(height: 8),
            _GameCard(
              result: 'L',
              opponent: 'vs Panthers',
              personalStats: '2-3, 1 RBI',
              date: 'Oct 12, 2024',
            ),
            const SizedBox(height: 8),
            _GameCard(
              result: 'W',
              opponent: 'vs Eagles',
              personalStats: '4-4, 3 RBI, 2 2B',
              date: 'Oct 10, 2024',
            ),

            const SizedBox(height: 20),

            // View All Button
            OutlinedButton(
              onPressed: () {
                // TODO: Navigate to full game history
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'VIEW ALL GAMES',
                style: GoogleFonts.tektur(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Single stat column (label + value)
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.tektur(
            fontSize: 11,
            color: AppColors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.tektur(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Team card showing user's team membership
class _TeamCard extends StatelessWidget {
  final String teamName;
  final String role;
  final VoidCallback onTap;

  const _TeamCard({
    required this.teamName,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOwner = role == 'OWNER';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary),
              ),
              child: const Icon(
                Icons.groups,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    style: GoogleFonts.tektur(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOwner ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role,
                      style: GoogleFonts.tektur(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOwner ? Colors.black : AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Game card showing recent game performance
class _GameCard extends StatelessWidget {
  final String result;
  final String opponent;
  final String personalStats;
  final String date;

  const _GameCard({
    required this.result,
    required this.opponent,
    required this.personalStats,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWin = result == 'W';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWin ? AppColors.primary : AppColors.error,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                result,
                style: GoogleFonts.tektur(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isWin ? AppColors.primary : AppColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent,
                  style: GoogleFonts.tektur(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  personalStats,
                  style: GoogleFonts.tektur(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.tektur(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

