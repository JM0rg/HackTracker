import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/team_providers.dart';
import '../providers/user_context_provider.dart';
import '../utils/messenger.dart';
import '../theme/app_colors.dart';

/// Full-page team creation form for onboarding flow
/// 
/// This screen is shown when a new user selects "Manage a Full Team" on the
/// welcome screen. It has a back button to return to the welcome screen and
/// no bottom nav/drawer until team is created.
class TeamCreationScreen extends ConsumerStatefulWidget {
  const TeamCreationScreen({super.key});

  @override
  ConsumerState<TeamCreationScreen> createState() => _TeamCreationScreenState();
}

class _TeamCreationScreenState extends ConsumerState<TeamCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Create the team
      await ref.read(teamsProvider.notifier).createTeam(
        name: _nameController.text.trim(),
        teamType: 'MANAGED',
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        // User context refresh is now awaited in team_providers.createTeam()
        // Reset loading state before navigating
        setState(() => _isSubmitting = false);
        
        // Pop back to WelcomeScreen - AuthGate will detect the user now has teams
        // and automatically route to DynamicHomeScreen (Team View)
        // The navigation itself confirms success to the user
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Messenger.showError(context, 'Failed to create team: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () {
            // Clear the hall pass when going back
            ref.read(creatingFirstTeamProvider.notifier).setCreating(false);
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Create Your Team'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.groups,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Set Up Your Team',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Create a team to manage your roster, track games, and record stats.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Team Name Field (Required)
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Team Name *',
                    hintText: 'e.g., Thunder Softball',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Team name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Team name must be at least 2 characters';
                    }
                    if (value.trim().length > 100) {
                      return 'Team name must be less than 100 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Team Description Field (Optional)
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'This helps players and fans find your team in Team Finder',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value != null && value.trim().length > 500) {
                      return 'Description must be less than 500 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'CREATE TEAM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Info text
                Text(
                  'You can add players to your team after it\'s created.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

