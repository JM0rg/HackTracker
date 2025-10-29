import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/user_context_provider.dart';
import '../providers/team_providers.dart';
import '../utils/messenger.dart';
import 'team_creation_screen.dart';

/// Welcome screen for first-time users with no teams
/// 
/// Presents two paths:
/// - Personal Stats: Creates a "Default" PERSONAL team
/// - Manage a Team: Routes to team creation (MANAGED)
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  String? _selectedOption; // 'personal' or 'managed'
  bool _isLoading = false;

  void _selectOption(String option) {
    setState(() => _selectedOption = option);
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSelection() async {
    if (_selectedOption == null || _isLoading) return;

    if (_selectedOption == 'personal') {
      await _handlePersonalPath();
    } else if (_selectedOption == 'managed') {
      await _handleManagerPath();
    }
  }

  Future<void> _handlePersonalPath() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Create "Default" PERSONAL team
      await apiService.createTeam(
        name: 'Default',
        teamType: 'PERSONAL',
        description: 'Personal stats tracking',
      );

      // Refresh user context
      await ref.read(userContextNotifierProvider.notifier).refresh();
      
      // Refresh teams list
      ref.invalidate(teamsProvider);

      if (mounted) {
        Messenger.showSuccess(context, 'Personal stats tracking enabled!');
      }
    } catch (e) {
      if (mounted) {
        Messenger.showError(context, 'Failed to set up personal tracking: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleManagerPath() async {
    setState(() => _isLoading = true);

    try {
      // Set the "hall pass" to allow bypassing welcome screen
      ref.read(creatingFirstTeamProvider.notifier).setCreating(true);
      
      if (mounted) {
        // Navigate to the team creation screen
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const TeamCreationScreen(),
          ),
        );
        
        // When they come back (either via back button or after creating team),
        // check if they created a team and refresh context
        await ref.read(userContextNotifierProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        Messenger.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo/title
                Icon(
                  Icons.sports_baseball,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Welcome to HackTracker!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'What would you like to track?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Personal Stats Button
                _OptionCard(
                  icon: Icons.person,
                  title: 'Track My Personal Stats',
                  description: 'Track your individual performance across teams',
                  onTap: _isLoading ? null : () => _selectOption('personal'),
                  isSelected: _selectedOption == 'personal',
                  onInfoTap: () => _showInfoDialog(
                    context,
                    'Track My Personal Stats',
                    'This option is perfect if you:\n\n'
                    '• Want to track your individual performance\n'
                    '• Not looking to manage a full roster of players\n'
                    '• Want the option to track stats across many teams you play for\n\n'
                    'This is for personal stat management, not team manegement. '
                    'You can filter and view your stats by team, season, or game that you create.',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Manage Team Button
                _OptionCard(
                  icon: Icons.people,
                  title: 'Manage a Full Team',
                  description: 'Coach and manage a full roster with lineups',
                  onTap: _isLoading ? null : () => _selectOption('managed'),
                  isSelected: _selectedOption == 'managed',
                  onInfoTap: () => _showInfoDialog(
                    context,
                    'Manage a Full Team',
                    'This option is perfect if you:\n\n'
                    '• Coach or manage a team\n'
                    '• Need to track multiple players\n'
                    '• Want to set lineups and game schedules\n'
                    '• Need team-level statistics and reports\n'
                    '• Manage games, seasons, and tournaments\n\n'
                    'You\'ll be able to add players to your roster (yourself included), create game lineups, '
                    'and track stats for your entire team. Perfect for coaches, team managers, '
                    'or anyone organizing a full squad.',
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Confirmation Button (always visible)
                ElevatedButton(
                  onPressed: _selectedOption != null && !_isLoading ? _confirmSelection : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                    backgroundColor: _selectedOption != null && !_isLoading
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade700,
                    disabledBackgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedOption == null
                        ? 'SELECT AN OPTION'
                        : _isLoading
                            ? 'PROCESSING...'
                            : 'CONFIRM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _selectedOption != null && !_isLoading
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Reassurance text
                Text(
                  "You can always add the other option later!",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;
  final bool isSelected;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.onInfoTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.primary : null,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Info button in top-right corner
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              onPressed: onInfoTap,
              tooltip: 'More information',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

