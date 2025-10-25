import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../theme/app_colors.dart';
import '../providers/team_providers.dart';
import '../providers/user_providers.dart';

/// Collapsible sidebar drawer with navigation and team management
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await Amplify.Auth.signOut();
      
      // Clear all cached data on logout
      ref.invalidate(teamsProvider);
      ref.invalidate(currentUserProvider);
    } on AuthException catch (e) {
      safePrint('Error signing out: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.message}'),
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
                    style: GoogleFonts.tektur(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Slowpitch Stats Tracking',
                    style: GoogleFonts.tektur(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      letterSpacing: 1,
                    ),
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

                  // Teams list (placeholder - will be dynamic)
                  _DrawerItem(
                    icon: Icons.groups,
                    title: 'Rockets',
                    subtitle: 'Owner',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to team view
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

                  // Team Management (only shown if user is owner/admin)
                  const SizedBox(height: 16),
                  _DrawerSectionHeader(title: 'ROCKETS MANAGEMENT'),
                  
                  _DrawerSubItem(
                    icon: Icons.event,
                    title: 'Seasons',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to seasons
                    },
                  ),
                  _DrawerSubItem(
                    icon: Icons.emoji_events,
                    title: 'Tournaments',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to tournaments
                    },
                  ),
                  _DrawerSubItem(
                    icon: Icons.people,
                    title: 'Roster',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to roster
                    },
                  ),
                  _DrawerSubItem(
                    icon: Icons.sports_baseball,
                    title: 'Games',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to games
                    },
                  ),
                  _DrawerSubItem(
                    icon: Icons.settings,
                    title: 'Team Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to team settings
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
        style: GoogleFonts.tektur(
          fontSize: 11,
          color: AppColors.textTertiary,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Main drawer menu item
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: GoogleFonts.tektur(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.tektur(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
        style: GoogleFonts.tektur(
          color: AppColors.textLight,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      dense: true,
    );
  }
}

