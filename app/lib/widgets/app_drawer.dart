import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../theme/app_colors.dart';
import '../providers/team_providers.dart';
import '../providers/user_providers.dart';
import '../providers/user_context_provider.dart';
import '../services/auth_service.dart';

/// Collapsible sidebar drawer with navigation and team management
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await AuthService.signOut();
      
      // Clear all cached data on logout
      ref.invalidate(teamsProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(userContextNotifierProvider);

      if (context.mounted) {
        Navigator.pop(context); // Close drawer
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HACKTRACKER',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Slowpitch Stats Tracking',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Scrollable menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // My Stats
                  _DrawerItem(
                    icon: Icons.bar_chart,
                    title: 'My Stats',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to player stats
                    },
                  ),

                  const SizedBox(height: 16),
                  _DrawerSectionHeader(title: 'MY TEAMS'),

                  // Dynamic teams list
                  Consumer(
                    builder: (context, ref, child) {
                      final teamsAsync = ref.watch(teamsProvider);
                      final selectedTeam = ref.watch(selectedTeamProvider);
                      
                      return teamsAsync.when(
                        loading: () => const _DrawerItem(
                          icon: Icons.hourglass_empty,
                          title: 'Loading teams...',
                          onTap: null,
                        ),
                        error: (e, st) => _DrawerItem(
                          icon: Icons.error_outline,
                          title: 'Error loading teams',
                          onTap: () {},
                        ),
                        data: (teams) {
                          if (teams.isEmpty) {
                            return const _DrawerItem(
                              icon: Icons.info_outline,
                              title: 'No teams yet',
                              onTap: null,
                            );
                          }
                          
                          return Column(
                            children: teams.map((team) {
                              final isSelected = selectedTeam?.teamId == team.teamId;
                              return _DrawerItem(
                                icon: Icons.groups,
                                title: team.name,
                                subtitle: team.displayRole,
                                isSelected: isSelected,
                                onTap: () {
                                  ref.read(selectedTeamProvider.notifier).state = team;
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),

                  // Create team button
                  _DrawerItem(
                    icon: Icons.add_circle_outline,
                    title: 'Create Team',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to create team
                    },
                  ),

                ],
              ),
            ),

            // Bottom section
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to settings
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    onTap: () => _signOut(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header in the drawer
class _DrawerSectionHeader extends StatelessWidget {
  final String title;

  const _DrawerSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Main drawer menu item
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isSelected;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppColors.primary : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.labelSmall,
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }
}

/// Sub-item (indented) for team management
class _DrawerSubItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerSubItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Icon(icon, color: AppColors.secondary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      dense: true,
    );
  }
}

