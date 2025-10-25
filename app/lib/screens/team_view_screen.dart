import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hacktracker/services/api_service.dart';
import '../theme/app_colors.dart';
import '../providers/team_providers.dart';

/// Team View - Shows team-specific stats and roster
class TeamViewScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRecruiter;
  
  const TeamViewScreen({super.key, this.onNavigateToRecruiter});

  @override
  ConsumerState<TeamViewScreen> createState() => _TeamViewScreenState();
}

class _TeamViewScreenState extends ConsumerState<TeamViewScreen> {
  Team? _selectedTeam;

  Future<void> _showCreateTeamDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'CREATE TEAM',
          style: GoogleFonts.tektur(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'TEAM NAME',
                hintText: 'Enter team name',
              ),
              style: GoogleFonts.tektur(),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'DESCRIPTION (Optional)',
                hintText: 'Enter team description',
              ),
              style: GoogleFonts.tektur(),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team name is required')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _createTeam(
        nameController.text.trim(),
        descriptionController.text.trim(),
      );
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _createTeam(String name, String description) async {
    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await ref.read(teamsProvider.notifier).createTeam(
        name: name,
        description: description.isEmpty ? null : description,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "$name" created successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create team: ${e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showUpdateTeamDialog(Team team) async {
    if (!team.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only team owners can edit teams')),
      );
      return;
    }

    final nameController = TextEditingController(text: team.name);
    final descriptionController = TextEditingController(text: team.description);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'EDIT TEAM',
          style: GoogleFonts.tektur(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'TEAM NAME',
              ),
              style: GoogleFonts.tektur(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'DESCRIPTION',
              ),
              style: GoogleFonts.tektur(),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team name is required')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _updateTeam(
        team.teamId,
        nameController.text.trim(),
        descriptionController.text.trim(),
      );
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _updateTeam(String teamId, String name, String description) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await ref.read(teamsProvider.notifier).updateTeam(
        teamId: teamId,
        name: name,
        description: description.isEmpty ? null : description,
      );
      
      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team updated successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update team: ${e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDeleteTeam(Team team) async {
    if (!team.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only team owners can delete teams')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'DELETE TEAM?',
          style: GoogleFonts.tektur(
            color: AppColors.error,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${team.name}"?\n\nThis action cannot be undone.',
          style: GoogleFonts.tektur(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteTeam(team);
    }
  }

  Future<void> _deleteTeam(Team team) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await ref.read(teamsProvider.notifier).deleteTeam(team.teamId);
      
      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "${team.name}" deleted'),
          backgroundColor: AppColors.primary,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);

    return teamsAsync.when(
      // Loading state - only show spinner if no cached data
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      
      // Error state
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              style: GoogleFonts.tektur(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(teamsProvider),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
      
      // Data state
      data: (teams) {
        // Empty state - user not on any teams
        if (teams.isEmpty) {
          return _buildEmptyState();
        }

        // Set selected team if not set yet
        if (_selectedTeam == null || !teams.any((t) => t.teamId == _selectedTeam!.teamId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedTeam = teams.first;
            });
          });
        }

        // User has teams - show team view with pull-to-refresh
        return RefreshIndicator(
          onRefresh: () => ref.refresh(teamsProvider.future),
          color: AppColors.primary,
          child: _buildTeamView(teams),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO TEAMS YET',
              style: GoogleFonts.tektur(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track stats with your team!\nCreate a team or wait for an invitation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.tektur(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showCreateTeamDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'CREATE TEAM',
                  style: GoogleFonts.tektur(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // TODO: Navigate to invitations
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mail_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'VIEW INVITATIONS',
                    style: GoogleFonts.tektur(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  // Badge for pending invites
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '2',
                      style: GoogleFonts.tektur(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Divider
            Container(
              height: 1,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 40),
            ),
            const SizedBox(height: 24),
            // Recruiter prompt
            Text(
              'LOOKING FOR A TEAM?',
              style: GoogleFonts.tektur(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse available teams and players in the Recruiter tab',
              textAlign: TextAlign.center,
              style: GoogleFonts.tektur(
                fontSize: 12,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: widget.onNavigateToRecruiter,
              icon: const Icon(Icons.person_search, size: 20),
              label: Text(
                'OPEN RECRUITER',
                style: GoogleFonts.tektur(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamView(List<Team> teams) {
    if (_selectedTeam == null) {
      return const Center(child: Text('No team selected'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Team Selector (if multiple teams)
            if (teams.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<Team>(
                        value: _selectedTeam,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox(),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
                        items: teams.map((team) {
                          return DropdownMenuItem<Team>(
                            value: team,
                            child: Text(
                              team.name,
                              style: GoogleFonts.tektur(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (team) {
                          setState(() {
                            _selectedTeam = team;
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selectedTeam!.isOwner
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedTeam!.role.toUpperCase().replaceAll('-', ' '),
                        style: GoogleFonts.tektur(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _selectedTeam!.isOwner ? Colors.black : AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Team action buttons (Edit/Delete for owners)
            if (_selectedTeam!.isOwner) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showUpdateTeamDialog(_selectedTeam!),
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        'EDIT TEAM',
                        style: GoogleFonts.tektur(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteTeam(_selectedTeam!),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(
                        'DELETE',
                        style: GoogleFonts.tektur(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Team Stats Summary
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
                    'TEAM STATS - 2024',
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
                      _StatColumn(label: 'WINS', value: '12'),
                      _StatColumn(label: 'LOSSES', value: '8'),
                      _StatColumn(label: 'AVG', value: '.298'),
                      _StatColumn(label: 'HR', value: '47'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'QUICK ACTIONS',
                  style: GoogleFonts.tektur(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCreateTeamDialog,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(
                    'NEW TEAM',
                    style: GoogleFonts.tektur(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.sports_baseball,
                    label: 'RECORD GAME',
                    onTap: () {
                      // TODO: Navigate to record game
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.event,
                    label: 'VIEW SCHEDULE',
                    onTap: () {
                      // TODO: Navigate to schedule
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Roster Preview
            Text(
              'ROSTER',
              style: GoogleFonts.tektur(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            _PlayerCard(name: 'Jack Morgan', stats: '.342 AVG • 12 HR'),
            const SizedBox(height: 8),
            _PlayerCard(name: 'Mike Smith', stats: '.315 AVG • 8 HR'),
            const SizedBox(height: 8),
            _PlayerCard(name: 'Sarah Johnson', stats: '.298 AVG • 5 HR'),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () {
                // TODO: Navigate to full roster
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
                'VIEW FULL ROSTER',
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

/// Stat column widget
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.tektur(
                fontSize: 11,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Player card widget
class _PlayerCard extends StatelessWidget {
  final String name;
  final String stats;

  const _PlayerCard({required this.name, required this.stats});

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary),
            ),
            child: const Icon(
              Icons.person,
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
                  name,
                  style: GoogleFonts.tektur(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats,
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

