import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/custom_text_styles.dart';
import '../providers/user_providers.dart';

/// Profile screen showing user info and settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
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

            _SettingsItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to edit profile
              },
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                // TODO: Navigate to notification settings
              },
            ),
            _SettingsItem(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              onTap: () {
                // TODO: Navigate to privacy settings
              },
            ),
            _SettingsItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // TODO: Navigate to help
              },
            ),
            _SettingsItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                // TODO: Show about dialog
              },
            ),

            const SizedBox(height: 32),

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

/// Settings item widget
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }
}

