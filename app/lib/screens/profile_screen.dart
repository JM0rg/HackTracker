import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/custom_text_styles.dart';
import '../theme/decoration_styles.dart';
import '../providers/user_providers.dart';
import '../providers/team_providers.dart';
import '../providers/user_context_provider.dart';
import '../services/auth_service.dart';
import '../widgets/ui_helpers.dart';

/// Profile screen showing user info and settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Sign Out',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Sign out from Amplify
      await AuthService.signOut();
      
      // Clear all cached data
      ref.invalidate(teamsProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(userContextNotifierProvider);

      if (context.mounted) {
        showSuccess(context, 'Signed out successfully');
      }
    } catch (e) {
      if (context.mounted) {
        showError(context, 'Error signing out: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(
        child: LoadingIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load user info',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(currentUserProvider),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
      data: (user) => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: DecorationStyles.primaryBorder(),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PLAYER',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings Section
            Text(
              'SETTINGS',
              style: Theme.of(context).extension<CustomTextStyles>()!.sectionHeader.copyWith(color: AppColors.primary),
            ),

            const SizedBox(height: 12),

            ListItemCard(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to edit profile
              },
            ),
            ListItemCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                // TODO: Navigate to notification settings
              },
            ),
            ListItemCard(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              onTap: () {
                // TODO: Navigate to privacy settings
              },
            ),
            ListItemCard(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // TODO: Navigate to help
              },
            ),
            ListItemCard(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                // TODO: Show about dialog
              },
            ),

            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _signOut(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'SIGN OUT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Version
            Center(
              child: Text(
                'HackTracker v1.0.0',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    ); // End of when()
  }
}
