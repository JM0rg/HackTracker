import 'package:flutter/material.dart';
import 'package:hacktracker/theme/app_colors.dart';
import 'package:hacktracker/services/auth_service.dart';
import 'package:hacktracker/screens/home_screen.dart';
import '../screens/login_screen.dart';

/// Auth gate that checks if user is already logged in
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthStatus>(
      future: AuthService.validateAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        final authStatus = snapshot.data ?? AuthStatus.error;

        // Handle authentication errors
        if (authStatus == AuthStatus.error) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please restart the app',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user has valid authentication
        if (authStatus.isValid) {
          return const HomeScreen();
        }

        // User needs to sign in (expired token, invalid token, or not signed in)
        return const LoginScreen();
      },
    );
  }
}
