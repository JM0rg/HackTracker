import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_context_provider.dart';
import '../providers/team_providers.dart';
import '../providers/api_provider.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  'Which one best describes you?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Personal Stats Button
                _OptionCard(
                  icon: Icons.person,
                  title: 'Solo User',
                  description: 'Looking to track your own stats or join a team',
                  onTap: _isLoading ? null : () => _selectOption('personal'),
                  isSelected: _selectedOption == 'personal',
                ),
                
                const SizedBox(height: 16),
                
                // Manage Team Button
                _OptionCard(
                  icon: Icons.people,
                  title: 'Team Manager',
                  description: 'Create, Manage, and track stats for a full Roster of players',
                  onTap: _isLoading ? null : () => _selectOption('managed'),
                  isSelected: _selectedOption == 'managed',
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
  final bool isSelected;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
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
      child: InkWell(
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
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    );
  }
}

