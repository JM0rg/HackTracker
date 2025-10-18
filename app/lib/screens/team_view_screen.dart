import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hacktracker/services/api_service.dart';
import 'package:hacktracker/config/app_config.dart';

/// Team View - Shows team-specific stats and roster
class TeamViewScreen extends StatefulWidget {
  const TeamViewScreen({super.key});

  @override
  State<TeamViewScreen> createState() => _TeamViewScreenState();
}

class _TeamViewScreenState extends State<TeamViewScreen> {
  List<Team>? _teams;
  Team? _selectedTeam;
  bool _isLoading = true;
  String? _errorMessage;
  
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(baseUrl: 'https://cgz1guhkf1.execute-api.us-east-1.amazonaws.com');
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teams = await _apiService.listTeams();
      setState(() {
        _teams = teams;
        _selectedTeam = teams.isNotEmpty ? teams.first : null;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load teams: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateTeamDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'CREATE TEAM',
          style: GoogleFonts.tektur(
            color: const Color(0xFF10B981),
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
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      await _apiService.createTeam(name: name, description: description);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Reload teams
      await _loadTeams();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "$name" created successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create team: ${e.message}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
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
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'EDIT TEAM',
          style: GoogleFonts.tektur(
            color: const Color(0xFF10B981),
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
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      await _apiService.updateTeam(
        teamId: teamId,
        name: name,
        description: description,
      );
      
      if (!mounted) return;
      Navigator.pop(context);
      await _loadTeams();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update team: ${e.message}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
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
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'DELETE TEAM?',
          style: GoogleFonts.tektur(
            color: const Color(0xFFEF4444),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${team.name}"?\n\nThis action cannot be undone.',
          style: GoogleFonts.tektur(color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
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
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      await _apiService.deleteTeam(team.teamId);
      
      if (!mounted) return;
      Navigator.pop(context);
      await _loadTeams();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "${team.name}" deleted'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.tektur(color: const Color(0xFFE2E8F0)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTeams,
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    // Empty state - user not on any teams
    if (_teams == null || _teams!.isEmpty) {
      return _buildEmptyState();
    }

    // User has teams - show team view
    return _buildTeamView();
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
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 48,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO TEAMS YET',
              style: GoogleFonts.tektur(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track stats with your team!\nCreate a team or wait for an invitation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.tektur(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showCreateTeamDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
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
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
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
                      color: const Color(0xFF10B981),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTeamView() {
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
            if (_teams!.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<Team>(
                        value: _selectedTeam,
                        dropdownColor: const Color(0xFF1E293B),
                        underline: const SizedBox(),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                        items: _teams!.map((team) {
                          return DropdownMenuItem<Team>(
                            value: team,
                            child: Text(
                              team.name,
                              style: GoogleFonts.tektur(
                                fontSize: 16,
                                color: const Color(0xFFE2E8F0),
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
                            ? const Color(0xFF10B981)
                            : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedTeam!.role.toUpperCase(),
                        style: GoogleFonts.tektur(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _selectedTeam!.isOwner ? Colors.black : const Color(0xFF94A3B8),
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
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
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
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
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
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'TEAM STATS - 2024',
                    style: GoogleFonts.tektur(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
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
                    color: const Color(0xFF10B981),
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
                    foregroundColor: const Color(0xFF34D399),
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
                color: const Color(0xFF10B981),
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
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
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
            color: const Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.tektur(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF10B981),
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.tektur(
                fontSize: 11,
                color: const Color(0xFFE2E8F0),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF10B981),
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
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stats,
                  style: GoogleFonts.tektur(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}

