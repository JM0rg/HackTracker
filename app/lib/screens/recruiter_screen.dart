import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Recruiter Hub - Browse players/subs and create free agent profile
class RecruiterScreen extends StatelessWidget {
  const RecruiterScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                Icons.person_search,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'RECRUITER HUB',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Find available players or create your free agent profile',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null, // Disabled - coming soon
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textTertiary,
                  disabledBackgroundColor: AppColors.surface,
                  disabledForegroundColor: AppColors.textTertiary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'BROWSE PLAYERS',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null, // Disabled - coming soon
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  disabledForegroundColor: AppColors.textTertiary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'CREATE MY PROFILE',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

