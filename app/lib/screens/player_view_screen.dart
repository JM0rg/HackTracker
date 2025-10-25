import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Player View - Shows user's personal stats aggregated across all teams
class PlayerViewScreen extends StatelessWidget {
  const PlayerViewScreen({super.key});

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

            // Performance Chart Placeholder
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
                    'PERFORMANCE TREND',
                    style: GoogleFonts.tektur(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Chart Coming Soon',
                        style: GoogleFonts.tektur(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent At-Bats
            Text(
              'RECENT AT-BATS',
              style: GoogleFonts.tektur(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // At-Bat Cards (placeholder)
            _AtBatCard(
              result: '2B',
              game: 'Rockets vs Tigers',
              date: 'Oct 15, 2024',
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 8),
            _AtBatCard(
              result: '1B',
              game: 'Solo Practice',
              date: 'Oct 12, 2024',
              icon: Icons.sports_baseball,
            ),
            const SizedBox(height: 8),
            _AtBatCard(
              result: 'HR',
              game: 'Rockets vs Panthers',
              date: 'Oct 10, 2024',
              icon: Icons.rocket_launch,
            ),

            const SizedBox(height: 20),

            // View All Button
            OutlinedButton(
              onPressed: () {
                // TODO: Navigate to full at-bat history
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
                'VIEW ALL AT-BATS',
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

/// At-Bat card showing recent activity
class _AtBatCard extends StatelessWidget {
  final String result;
  final String game;
  final String date;
  final IconData icon;

  const _AtBatCard({
    required this.result,
    required this.game,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(color: AppColors.primary),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      result,
                      style: GoogleFonts.tektur(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      game,
                      style: GoogleFonts.tektur(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.tektur(
                    fontSize: 12,
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

